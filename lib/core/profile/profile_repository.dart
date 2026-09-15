// lib/core/repositories/profile_repository.dart

import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';

class ProfileRepository {
  final ApiServices _api = ApiServices();

  Future<Student> fetchProfile() async {
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
