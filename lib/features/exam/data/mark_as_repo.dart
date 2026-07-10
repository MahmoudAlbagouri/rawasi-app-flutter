// lib/features/exam/data/mark_as_repo.dart
import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';

class MarkAsRepo {
  final ApiServices _api = ApiServices();

  Future<void> markAs(
    int dailyTaskId,
    String markAsValue,
    int dayNumber,
  ) async {
    final data = FormData.fromMap({
      'mark_as': markAsValue,
      'day_number': dayNumber.toString(),
    });

    final response = await _api.postFormData('/mark-as/$dailyTaskId', data);

    if (response is ApiError) {
      throw response;
    }

    // يمكن تجاهل الاستجابة إذا لم تكن ضرورية
  }
}
