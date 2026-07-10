// lib/features/exam/data/exam_repo.dart

import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/exam/data/daily_task_response.dart';
import 'package:rawasi_app_n/features/exam/data/question_item.dart';

class ExamRepo {
  final ApiServices _api = ApiServices();

  Future<List<QuestionItem>> fetchQuestions(int courseId, int dayId) async {
    final response = await _api.get('/daily-tasks/$dayId/$courseId');

    if (response is ApiError) {
      throw response;
    }

    if (response is Map<String, dynamic>) {
      final parsed = DailyTaskResponse.fromJson(response);
      return parsed.data
          .where((item) => item.dayable.type == 'question')
          .map((item) => QuestionItem.fromDailyTaskItem(item)) // ← تعديل هنا
          .toList();
    }

    throw Exception('Invalid response format');
  }
}
