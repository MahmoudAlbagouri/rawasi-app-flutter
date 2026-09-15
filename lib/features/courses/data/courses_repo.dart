import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/lesson.dart';
import 'package:rawasi_app_n/features/courses/data/question.dart';

class CoursesRepo {
  final ApiServices _api = ApiServices();

  Future<List<Course>> fetchCourses() async {
    final response = await _api.get('/courses');
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as List? ?? [];
      return data.map((e) => Course.fromJson(e)).toList();
    }
    throw ApiError(message: 'فشل تحميل المواد الدراسية');
  }

  Future<List<Lesson>> fetchLessons(int courseId) async {
    final response = await _api.get('/courses/$courseId/lessons');
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as List? ?? [];
      return data.map((e) => Lesson.fromJson(e)).toList();
    }
    throw ApiError(message: response is Map ? (response['message'] ?? 'فشل تحميل الدروس') : 'فشل تحميل الدروس');
  }

  Future<List<Question>> fetchQuestions(int lessonId) async {
    final response = await _api.get('/lessons/$lessonId/questions');
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as List? ?? [];
      return data.map((e) => Question.fromJson(e)).toList();
    }
    throw ApiError(message: response is Map ? (response['message'] ?? 'فشل تحميل الأسئلة') : 'فشل تحميل الأسئلة');
  }

  /// Returns `{ lesson_completed, completed_questions_count, questions_count, next_lesson }`.
  Future<Map<String, dynamic>> completeQuestion(
    int questionId, {
    int? durationSeconds,
  }) async {
    final response = await _api.post('/questions/$questionId/complete', {
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic> && response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw ApiError(message: response is Map ? (response['message'] ?? 'فشل تحديد السؤال كمكتمل') : 'فشل تحديد السؤال كمكتمل');
  }

  /// Returns `{ lesson, next_lesson }`.
  Future<Map<String, dynamic>> completeLesson(
    int lessonId, {
    int? durationSeconds,
  }) async {
    final response = await _api.post('/lessons/$lessonId/complete', {
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic> && response['success'] == true) {
      return response['data'] as Map<String, dynamic>;
    }
    throw ApiError(message: response is Map ? (response['message'] ?? 'فشل إنهاء الدرس') : 'فشل إنهاء الدرس');
  }
}
