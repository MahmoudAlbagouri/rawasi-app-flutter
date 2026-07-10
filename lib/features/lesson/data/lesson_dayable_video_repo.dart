// lib/features/lessons/data/lesson_dayable_video_repo.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/lesson/data/lesson_dayable_video.dart';

class LessonDetailsRepo {
  final ApiServices _api = ApiServices();

  Future<LessonDayableVideo> fetchLessonDetails(int courseId, int dayId) async {
    final response = await _api.get('/daily-tasks/$dayId/$courseId');

    print('🔍 API Response for dayId=$dayId, courseId=$courseId:');
    if (response is Map<String, dynamic>) {
      print(jsonEncode(response));
    } else if (response is String) {
      print('Response (String): $response');
    } else {
      print('Response (Other type): ${response.runtimeType} = $response');
    }

    if (response is Map<String, dynamic>) {
      if (response['success'] == true) {
        final data = response['data'] as List?;
        if (data != null && data.isNotEmpty) {
          return LessonDayableVideo.fromJson(data.first);
        }
      }
      final message = response['message'] as String?;
      throw Exception(message ?? 'فشل تحميل بيانات الدرس: لا توجد بيانات');
    }

    if (response is String) {
      throw Exception(response);
    }

    throw Exception('فشل تحميل بيانات الدرس: تنسيق غير متوقع');
  }

  // ✅ دالة جديدة: إكمال المهمة
  Future<bool> completeTask(int taskId, int dayNumber) async {
    try {
      final response = await _api.postFormData(
        '/complete-task/$taskId',
        FormData.fromMap({'day_number': dayNumber.toString()}),
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        print('✅ تم إكمال المهمة بنجاح: $taskId');
        return true;
      }

      final message = response is Map<String, dynamic>
          ? response['message'] as String?
          : response.toString();
      throw Exception(message ?? 'فشل في إكمال المهمة');
    } on Exception catch (e) {
      print('❌ خطأ في إكمال المهمة: $e');
      rethrow;
    }
  }
}
