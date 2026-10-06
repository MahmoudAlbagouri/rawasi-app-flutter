import 'package:rawasi_app_n/core/network/api_cache.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/lesson.dart';
import 'package:rawasi_app_n/features/courses/data/question.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';
import 'package:rawasi_app_n/features/stats/data/stats_repo.dart';

class CoursesRepo {
  final ApiServices _api = ApiServices();

  /// The course list (with per-course progress) for 30 s — read by home and
  /// المواد, both rebuilt on every tab switch. Cleared whenever a question
  /// or lesson is completed.
  static final ApiCache<List<Course>> _coursesCache = ApiCache(
    const Duration(seconds: 30),
  );

  /// Progress changed: everything that shows it must reload next time.
  static void invalidateProgress() {
    _coursesCache.invalidate();
    StatsRepo.invalidate();
    HomeRepo.invalidate();
  }

  Future<List<Course>> fetchCourses({bool force = false}) =>
      _coursesCache.get(_loadCourses, force: force);

  Future<List<Course>> _loadCourses() async {
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
    throw ApiError(
      message: response is Map
          ? (response['message'] ?? 'فشل تحميل الدروس')
          : 'فشل تحميل الدروس',
    );
  }

  Future<List<Question>> fetchQuestions(int lessonId) async {
    final response = await _api.get('/lessons/$lessonId/questions');
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic> && response['success'] == true) {
      final data = response['data'] as List? ?? [];
      return data.map((e) => Question.fromJson(e)).toList();
    }
    throw ApiError(
      message: response is Map
          ? (response['message'] ?? 'فشل تحميل الأسئلة')
          : 'فشل تحميل الأسئلة',
    );
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
      invalidateProgress();
      return response['data'] as Map<String, dynamic>;
    }
    throw ApiError(
      message: response is Map
          ? (response['message'] ?? 'فشل تحديد السؤال كمكتمل')
          : 'فشل تحديد السؤال كمكتمل',
    );
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
      invalidateProgress();
      return response['data'] as Map<String, dynamic>;
    }
    throw ApiError(
      message: response is Map
          ? (response['message'] ?? 'فشل إنهاء الدرس')
          : 'فشل إنهاء الدرس',
    );
  }
}
