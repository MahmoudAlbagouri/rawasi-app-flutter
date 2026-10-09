import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';

class ApiExceptions {
  /// Whether [error] means "could not reach the server or get a response
  /// back", rather than the server answering with an error.
  ///
  /// `error.response` is non-null whenever the server actually replied — a
  /// 401, a 403, a 500, anything — so that is excluded first and unconditionally:
  /// the server was reached, and this is not a connectivity problem whatever
  /// the DioExceptionType says.
  ///
  /// Everything else classified here is: never sent at all (connectionTimeout,
  /// the DioClient-level connect timeout), dropped mid-request
  /// (connectionError), too slow to answer (receiveTimeout/sendTimeout, which
  /// on a mobile network usually means a bad signal rather than a slow
  /// server), or DioExceptionType.unknown, which on this app's stack is almost
  /// always a raw SocketException (no network interface, DNS failure, airplane
  /// mode) that Dio could not classify more specifically.
  ///
  /// Excluded on purpose: `cancel` (the request was deliberately abandoned,
  /// not dropped) and `badCertificate` (a TLS problem, not "no connection").
  static bool isConnectivityIssue(DioException error) {
    if (error.response != null) return false;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.unknown:
        return true;
      default:
        return false;
    }
  }

  static const String connectivityMessage =
      'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';

  static ApiError handleError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic> && data['message'] != null) {
      return ApiError(
        message: data['message'],
        statusCode: error.response?.statusCode,
      );
    }

    if (isConnectivityIssue(error)) {
      return ApiError(message: connectivityMessage, isConnectivityIssue: true);
    }

    return ApiError(message: 'حدث خطأ غير متوقع، حاول مرة أخرى.');
  }
}
