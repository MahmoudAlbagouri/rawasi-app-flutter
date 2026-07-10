// lib/features/days/data/days_repo.dart

import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/days/data/day_lesson.dart';

class DaysResponse {
  final List<DayLesson> lessons;
  final int currentDay;
  final int expectedCurrentDay;

  DaysResponse({
    required this.lessons,
    required this.currentDay,
    required this.expectedCurrentDay,
  });
}

// lib/features/days/data/days_repo.dart

class DaysRepo {
  final ApiServices _apiServices = ApiServices();

  // ← أضف مُعاملات اختيارية للتجربة
  Future<DaysResponse> fetchDailyTasks({
    int? overrideCurrentDay,
    int? overrideExpectedCurrentDay,
  }) async {
    final response = await _apiServices.get('/daily-tasks');

    if (response is ApiError) {
      throw response;
    }

    if (response is! Map<String, dynamic>) {
      throw ApiError(message: 'استجابة غير متوقعة من السيرفر');
    }

    if (response['success'] != true) {
      final message =
          response['message'] as String? ?? 'فشل جلب المهام اليومية';
      throw ApiError(message: message);
    }

    final data = response['data'] as List?;
    if (data == null) {
      throw ApiError(message: 'لا توجد بيانات الأيام');
    }

    // استخدم القيم المُعطاة، أو ارجع إلى القيم الأصلية من الاستجابة
    final currentDay =
        overrideCurrentDay ?? (response['current_day'] as int? ?? 1);
    final expectedCurrentDay =
        overrideExpectedCurrentDay ??
        (response['expected_current_day'] as int? ?? 1);

    // في DaysRepo.fetchDailyTasks()

    final lessons = data
        .map(
          (item) => DayLesson.fromJson(
            item as Map<String, dynamic>,
            currentDay: currentDay,
            expectedCurrentDay: expectedCurrentDay,
          ),
        )
        .toList();

    return DaysResponse(
      lessons: lessons,
      currentDay: currentDay,
      expectedCurrentDay: expectedCurrentDay,
    );
  }
}
