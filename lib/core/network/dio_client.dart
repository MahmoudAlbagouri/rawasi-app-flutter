import 'dart:io'
    show ConnectionTask, HttpClient, SecureSocket, Socket, SocketException;

import 'package:dio/dio.dart';
import 'package:dio/io.dart' show IOHttpClientAdapter;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:rawasi_app_n/core/network/api_exceptions.dart';
import 'package:rawasi_app_n/core/network/network_status.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';

/// The one shared Dio, over ONE kept-alive connection to the server.
///
/// WHY ONE CONNECTION (measured against production, 2026-10-06):
///   - About 1 in 3 attempts to OPEN a new connection to rawasi.info is
///     silently dropped, while requests on a connection that is already open
///     are fast and reliable (0.12-0.4 s each).
///   - Home sent its 4 requests at once, so the app opened 4 new connections
///     together — in testing at least one was dropped EVERY time, and the
///     screen waited out the connect timeout. Other screens reused an open
///     connection, which is why only home was slow.
///   - So every request now shares a single kept-alive connection
///     ([maxConnectionsPerHost] = 1). Requests queue on it (~0.2-0.4 s each)
///     instead of each gambling on a new connection, and it is kept open
///     between screens ([idleTimeout]).
///
/// TIMEOUTS AND RETRY. A dropped connection attempt is abandoned after
/// [connectTimeout] (a healthy connect takes ~70 ms, so 3 s is generous even
/// on mobile data) and retried automatically. Measured: 4 requests went from
/// 15 s+ every time to about 1 s typically. See [shouldRetry] for exactly
/// which failures are retried, and why that is safe.
///
/// The underlying fault is on the server side (dropped TCP connections) and
/// should still be raised with the host; this keeps the app usable meanwhile.
class DioClient {
  static const Duration connectTimeout = Duration(seconds: 3);
  static const Duration receiveTimeout = Duration(seconds: 25);
  // Long enough for a receipt photo over a slow mobile connection.
  static const Duration sendTimeout = Duration(seconds: 60);

  static const int maxRetries = 3;

  /// One connection, reused by every request — see the class comment.
  static const int maxConnectionsPerHost = 1;

  /// How long the open connection is kept between requests, so moving from
  /// screen to screen does not reopen it.
  static const Duration idleTimeout = Duration(seconds: 90);

  static final Dio _dio = _create();

  Dio get dio => _dio;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: "https://rawasi.info/api/student",
        headers: {"Accept": 'application/json'},
        // No connectTimeout here, on purpose: Dio applies it to the whole wait
        // for a connection — INCLUDING time queued behind another request on
        // the single connection — so a request waiting its turn would "time
        // out" for nothing. The real connect limit is in [_connect] below.
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
      ),
    );

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..maxConnectionsPerHost = maxConnectionsPerHost
        // Dio's default is 3 s, which closed the connection between almost
        // every pair of screens — and each reopen risked being dropped.
        ..idleTimeout = idleTimeout
        ..connectionFactory = _connect,
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // In memory after the first read (PrefHelper) — no keystore trip.
          final token = await PrefHelper.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // Every successful response proves the connection works, whatever
        // was wrong with an earlier request - so the banner clears the
        // moment anything gets through, not only on a dedicated retry.
        onResponse: (response, handler) {
          NetworkStatus.isOffline.value = false;
          handler.next(response);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await PrefHelper.clearToken();
            return handler.next(error);
          }

          final options = error.requestOptions;
          final attempt = (options.extra['retry_attempt'] as int?) ?? 0;

          if (shouldRetry(error, attempt)) {
            await Future<void>.delayed(
              Duration(milliseconds: 250 * (attempt + 1)),
            );
            options.extra['retry_attempt'] = attempt + 1;
            try {
              return handler.resolve(await dio.fetch(options));
            } on DioException catch (e) {
              error = e;
            }
          }

          // Retries are exhausted (or never applied) and the request still
          // did not reach the server: tell the rest of the app so, instead
          // of leaving every screen to guess from its own error message.
          if (ApiExceptions.isConnectivityIssue(error)) {
            NetworkStatus.isOffline.value = true;
          }

          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Opens one TCP (+ TLS for https) connection, giving up after
  /// [connectTimeout]. Only the connect itself is timed — never time spent
  /// queued for the shared connection.
  ///
  /// HttpClient leaves TLS to a custom factory for direct https, so the
  /// secure socket is opened here. The timeout raises the same "timed out"
  /// SocketException HttpClient would, which Dio reports as a
  /// connectionTimeout — retried by [shouldRetry], since nothing was sent.
  static Future<ConnectionTask<Socket>> _connect(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    final host = proxyHost ?? uri.host;
    final port = proxyPort ?? uri.port;
    // Through a proxy, HttpClient secures the tunnel itself.
    final ConnectionTask<Socket> task =
        uri.scheme == 'https' && proxyHost == null
        ? await SecureSocket.startConnect(host, port)
        : await Socket.startConnect(host, port);

    return ConnectionTask.fromSocket(
      task.socket.timeout(
        connectTimeout,
        onTimeout: () {
          task.cancel();
          throw SocketException('Connection timed out after $connectTimeout');
        },
      ),
      task.cancel,
    );
  }

  /// Whether a failed request is retried.
  ///
  /// - A CONNECT timeout means the request never left the phone, so it is
  ///   safe to repeat for any method — the server cannot have acted on it.
  /// - Any other connection error may have happened mid-request, so only a
  ///   GET (which changes nothing) is repeated then.
  /// - Never: server responses (4xx/5xx), slow responses (the server is
  ///   working — repeating would double its load), cancellations, or uploads
  ///   (a FormData body is a one-shot stream and cannot be re-sent).
  @visibleForTesting
  static bool shouldRetry(DioException error, int attempt) {
    if (attempt >= maxRetries) return false;
    if (error.requestOptions.data is FormData) return false;

    final neverSent = error.type == DioExceptionType.connectionTimeout;
    if (neverSent) return true;

    return error.type == DioExceptionType.connectionError &&
        error.requestOptions.method.toUpperCase() == 'GET';
  }
}
