// lib/core/repositories/profile_repository.dart

import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/network/api_cache.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';

class ProfileRepository {
  final ApiServices _api = ApiServices();

  /// Almost every screen asks for the profile to decide what to show, and the
  /// bottom bar rebuilds tabs from scratch — so it is reused for a minute and
  /// shared between screens that ask at the same moment (ApiCache). Cleared
  /// on sign-in/out, profile completion and receipt upload; screens that must
  /// be exact (the subscription page) pass `force: true`.
  static final ApiCache<Student> _cache = ApiCache(const Duration(seconds: 60));

  static void invalidate() => _cache.invalidate();

  Future<Student> fetchProfile({bool force = false}) =>
      _cache.get(_load, force: force);

  Future<Student> _load() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final response = await _api.get('/profile');

    if (response is Map<String, dynamic> && response['success'] == true) {
      return Student.fromJson(response['data'] as Map<String, dynamic>);
    } else if (response is String) {
      throw Exception(response);
    } else {
      throw Exception('فشل تحميل ملف التعريف');
    }
  }
}
