import 'package:rawasi_app_n/core/network/api_cache.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';

class StatsRepo {
  final ApiServices _api = ApiServices();

  /// /analytics is the heaviest endpoint and both home and إحصائياتي read
  /// it, so one answer is shared for 30 s. Solving a question clears it
  /// (CoursesRepo), so progress is never shown stale after studying.
  static final ApiCache<StudentStats> _cache = ApiCache(
    const Duration(seconds: 30),
  );

  static void invalidate() => _cache.invalidate();

  Future<StudentStats> fetchStats({bool force = false}) =>
      _cache.get(_load, force: force);

  Future<StudentStats> _load() async {
    final response = await _api.get('/analytics');

    if (response is ApiError) throw response;

    if (response is Map<String, dynamic> && response['success'] == true) {
      return StudentStats.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiError(
      message: response is Map
          ? (response['message'] ?? 'فشل تحميل الإحصائيات')
          : 'فشل تحميل الإحصائيات',
    );
  }
}
