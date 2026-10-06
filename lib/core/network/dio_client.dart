import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:rawasi_app_n/core/utils/pref_helper.dart';

/// The one shared Dio. A single instance means one connection pool, so HTTP
/// keep-alive reuses connections instead of paying TCP + TLS on each request.
///
/// TIMEOUTS AND RETRY. Measured against production, a share of connections to
/// the server never complete. With no timeout, a screen waiting on one of
/// those sat on its spinner until Android gave up (30 s or more). Now:
///   - connecting gives up after [connectTimeout];
///   - a request that never reached the server is retried automatically
///     (twice, with a short pause), so one dropped connection costs about a
///     second instead of half a minute.
/// See [shouldRetry] for exactly which failures are retried, and why that is
/// safe.
class DioClient {
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 25);
  // Long enough for a receipt photo over a slow mobile connection.
  static const Duration sendTimeout = Duration(seconds: 60);

  static const int maxRetries = 2;

  static final Dio _dio = _create();

  Dio get dio => _dio;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: "https://rawasi.info/api/student",
        headers: {"Accept": 'application/json'},
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
      ),
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
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await PrefHelper.clearToken();
            return handler.next(error);
          }

          final options = error.requestOptions;
          final attempt = (options.extra['retry_attempt'] as int?) ?? 0;

          if (shouldRetry(error, attempt)) {
            await Future<void>.delayed(
              Duration(milliseconds: 400 * (attempt + 1)),
            );
            options.extra['retry_attempt'] = attempt + 1;
            try {
              return handler.resolve(await dio.fetch(options));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }

          return handler.next(error);
        },
      ),
    );

    return dio;
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
