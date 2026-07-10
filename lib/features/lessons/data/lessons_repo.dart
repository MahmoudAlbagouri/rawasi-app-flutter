import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/lessons/data/lessons_item.dart';

class LessonsRepo {
  final ApiServices _api = ApiServices();

  Future<List<LessonItem>> fetchLessonsByDay(int dayId) async {
    final response = await _api.get('/daily-tasks/$dayId');

    if (response is ApiError) {
      throw response;
    }

    if (response is! Map<String, dynamic>) {
      throw ApiError(message: 'استجابة غير متوقعة من الخادم');
    }

    if (response['success'] == true && response['data'] is List) {
      final List<dynamic> data = response['data'];
      return data
          .map((item) => LessonItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final message = response['message'];
    throw ApiError(message: message?.toString() ?? 'فشل جلب الدروس');
  }
}
