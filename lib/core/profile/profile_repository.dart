// lib/core/repositories/profile_repository.dart

import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/profile/student_profile.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';

class ProfileRepository {
  final ApiServices _api = ApiServices();

  Future<StudentProfile> fetchProfile() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final response = await _api.get('/profile');

    if (response is Map<String, dynamic> && response['success'] == true) {
      return StudentProfile.fromJson(response);
    } else if (response is String) {
      throw Exception(response);
    } else {
      throw Exception('فشل تحميل ملف التعريف');
    }
  }
}
