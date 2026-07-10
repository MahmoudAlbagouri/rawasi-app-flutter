import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';

class ApiExceptions {
  static ApiError handleError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic> && data['message'] != null) {
      return ApiError(message: data['message']);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiError(message: "Bad Connection");
      default:
        return ApiError(message: "خطأ غير متوقع");
    }
  }
}
