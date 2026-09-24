import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_exceptions.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';

class AuthRepo {
  final ApiServices apiServices = ApiServices();

  /// Parses the `{ success, data: { student, token } }` envelope shared by
  /// `login` and `check-otp`, saves the token, and returns the Student.
  Future<Student> _handleAuthResponse(dynamic response) async {
    if (response is ApiError) throw response;

    if (response is Map<String, dynamic>) {
      final success = response['success'] as bool? ?? false;
      final data = response['data'] as Map<String, dynamic>?;

      if (!success || data == null) {
        throw ApiError(message: response['message'] ?? 'فشلت العملية');
      }

      final studentJson = data['student'] as Map<String, dynamic>?;
      final token = data['token'] as String?;

      if (studentJson == null || token == null) {
        throw ApiError(message: 'استجابة غير متوقعة من الخادم');
      }

      await PrefHelper.saveToken(token);
      return Student.fromJson(studentJson);
    }

    throw ApiError(message: 'استجابة غير متوقعة من الخادم');
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------
  Future<Student> login(String phone, String password) async {
    try {
      final formData = FormData.fromMap({'phone': phone, 'password': password});
      final response = await apiServices.postFormData('/login', formData);
      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Register (step 1 — minimal): academic year, phone, password.
  // Sends an OTP; the account itself is created on check-otp.
  //
  // free first month: no plan_id, no referral_code and no code. plan_id is
  // nullable server-side and check-otp assigns the free-month plan; the
  // referral/discount rules are still there for the dashboard, the app just
  // stopped sending them.
  // ---------------------------------------------------------------------------
  Future<bool> register({
    required String academicYear,
    required String phone1,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'academic_year': academicYear,
        'phone1': phone1,
        'password': password,
        'password_confirmation': confirmPassword,
      };

      final response = await apiServices.post('/register', body);

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        if (success) return true;
        throw ApiError(message: response['message'] ?? 'فشل عملية التسجيل');
      }
      return false;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Check OTP — creates the account and returns the (profile-incomplete) student.
  // ---------------------------------------------------------------------------
  Future<Student> checkOtp(String phone, String otp) async {
    try {
      final formData = FormData.fromMap({'phone': phone, 'otp': otp});
      final response = await apiServices.postFormData('/check-otp', formData);
      return await _handleAuthResponse(response);
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Complete profile (step 2 — authenticated): everything registration skips.
  // ---------------------------------------------------------------------------
  /// free first month: the payload shrank to what the form still collects.
  /// school_branch became required; is_final_secondary, term_level, email,
  /// quran_level and every supervisor field were dropped and are no longer
  /// accepted by CompleteProfileRequest.
  Future<Student> completeProfile({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required String madhab,
    required String? schoolBranch,
    required String instituteName,
    required String governorate,
    required String city,
    String? phone2,
    bool? isWhatsapp,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'birth_date': birthDate,
        'madhab': madhab,
        'institute_name': instituteName,
        'governorate': governorate,
        'city': city,
      };
      if (schoolBranch != null && schoolBranch.isNotEmpty) {
        body['school_branch'] = schoolBranch;
      }
      if (phone2 != null && phone2.isNotEmpty) body['phone2'] = phone2;
      if (isWhatsapp != null) body['is_whatsapp'] = isWhatsapp ? 1 : 0;

      final response = await apiServices.post('/complete-profile', body);

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        final data = response['data'] as Map<String, dynamic>?;
        if (success && data != null) {
          return Student.fromJson(data);
        }
        throw ApiError(message: response['message'] ?? 'فشل استكمال البيانات');
      }
      throw ApiError(message: 'استجابة غير متوقعة من الخادم');
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    try {
      final response = await apiServices.post('/logout', {});
      if (response is Map &&
          (response['success'] == true || response['status'] == true)) {
        await PrefHelper.clearToken();
      } else {
        await PrefHelper.clearToken();
      }
    } catch (e) {
      await PrefHelper.clearToken();
      throw ApiError(message: 'تم الخروج محلياً مع تعذر إبلاغ السيرفر');
    }
  }

  Future<bool> hasToken() async {
    final token = await PrefHelper.getToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Forget Password - Send OTP
  // ---------------------------------------------------------------------------
  Future<void> sendForgetPasswordOtp(String phone) async {
    try {
      final formData = FormData.fromMap({'phone': phone});
      final response = await apiServices.postFormData(
        "/forget-password",
        formData,
      );

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        if (!success) {
          throw ApiError(
            message: response['message'] ?? "فشل إرسال رمز التحقق",
          );
        }
      } else {
        throw ApiError(message: "استجابة غير متوقعة من الخادم");
      }
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Forget Password - Check OTP
  // ---------------------------------------------------------------------------
  Future<void> checkForgetPasswordOtp(String phone, String otp) async {
    try {
      final formData = FormData.fromMap({'phone': phone, 'otp': otp});
      final response = await apiServices.postFormData(
        "/check-forget-password-otp",
        formData,
      );

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        if (!success) {
          throw ApiError(message: response['message'] ?? "رمز التحقق غير صحيح");
        }
      } else {
        throw ApiError(message: "استجابة غير متوقعة من الخادم");
      }
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Forget Password - Update Password
  // ---------------------------------------------------------------------------
  Future<void> updateForgetPassword({
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final formData = FormData.fromMap({
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      final response = await apiServices.postFormData(
        "/update-forget-password",
        formData,
      );

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        if (!success) {
          throw ApiError(
            message: response['message'] ?? "فشل تحديث كلمة المرور",
          );
        }
      } else {
        throw ApiError(message: "استجابة غير متوقعة من الخادم");
      }
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Check if phone exists
  // ---------------------------------------------------------------------------
  Future<bool> checkPhoneExists(String phone) async {
    try {
      final formData = FormData.fromMap({'phone': phone});
      final response = await apiServices.postFormData(
        "/check-phone-exists",
        formData,
      );

      if (response is ApiError) {
        if (response.message.contains('موجود') ||
            response.message.contains('exists')) {
          return false;
        }
        return true;
      }

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        return !success;
      }

      return true;
    } on DioException catch (e) {
      return true;
    } catch (e) {
      return true;
    }
  }
}
