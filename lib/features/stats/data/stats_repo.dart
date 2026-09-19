import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';

class StatsRepo {
  final ApiServices _api = ApiServices();

  Future<StudentStats> fetchStats() async {
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
