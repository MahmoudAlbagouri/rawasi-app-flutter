import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_exceptions.dart';
import 'package:rawasi_app_n/core/network/dio_client.dart';

class ApiServices {
  final DioClient _dioClient = DioClient();

  Future<dynamic> get(String endPoints) async {
    try {
      final response = await _dioClient.dio.get(endPoints);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  Future<dynamic> post(String endPoints, Map<String, dynamic> body) async {
    try {
      final response = await _dioClient.dio.post(endPoints, data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  Future<dynamic> put(String endPoints, Map<String, dynamic> body) async {
    try {
      final response = await _dioClient.dio.put(endPoints, data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  Future<dynamic> delete(String endPoints, Map<String, dynamic> body) async {
    try {
      final response = await _dioClient.dio.delete(endPoints, data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  // 👇 دالة POST جديدة للـ FormData
  Future<dynamic> postFormData(String endPoints, FormData data) async {
    try {
      final response = await _dioClient.dio.post(endPoints, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('API Error: ${e.response?.data}'); // ← طباعة الرد الكامل
      }
      return ApiExceptions.handleError(e);
    }
  }

  Future<dynamic> deleteFormData(String endPoints, FormData data) async {
    try {
      final response = await _dioClient.dio.delete(endPoints, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('DELETE API Error: ${e.response?.data}');
      }
      return ApiExceptions.handleError(e);
    }
  }
}
