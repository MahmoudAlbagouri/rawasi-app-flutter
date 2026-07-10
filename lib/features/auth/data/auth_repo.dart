import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_exceptions.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/auth/data/user_model.dart';

class AuthRepo {
  final ApiServices apiServices = ApiServices();

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------
  Future<UserModel?> login(String phone, String password) async {
    try {
      final response = await apiServices.post("/login", {
        'phone': phone,
        'password': password,
      });

      // إذا كانت الخدمة تعيد خطأ من نوع ApiError مباشرة
      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final bool success = response['success'] ?? false;
        final String message = response['message'] ?? "فشل تسجيل الدخول";
        final dynamic data = response['data'];

        // التحقق من نجاح العملية وجودة البيانات
        if (!success || data == null || data == "") {
          throw ApiError(message: message);
        }

        final user = UserModel.fromJson(response);

        if (user.token != null && user.token!.isNotEmpty) {
          await PrefHelper.saveToken(user.token!);
          print('✅ تم استلام وحفظ التوكن بنجاح');
        }

        return user;
      } else {
        throw ApiError(message: "استجابة غير معروفة من السيرفر");
      }
    } on DioException catch (e) {
      // تصحيح النوع هنا ليلتقط أخطاء الشبكة
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: "حدث خطأ: ${e.toString()}");
    }
  }

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String gender,
    required String birthDate,
    required bool isFinalSecondary,
    required String schoolBranch,
    required String instituteName,
    required String governorate,
    required String city,
    required String phone1,
    String? phone2,
    required bool isWhatsapp,
    required String email,
    required String quranLevel,
    required String doctrine,
    required String supervisorName,
    required String supervisorRelation,
    required String supervisorPhone,
    required String password,
    required String confirmPassword,
    String? supervisor2Name,
    String? supervisor2Relation,
    String? supervisor2Phone,
    String? referralCode,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'birth_date': birthDate,
        'is_final_secondary': isFinalSecondary ? 1 : 0,
        'school_branch': schoolBranch,
        'institute_name': instituteName,
        'governorate': governorate,
        'city': city,
        'phone1': phone1,
        'phone2': phone2,
        'referral_code': referralCode,
        'is_whatsapp': isWhatsapp ? 1 : 0,
        'email': email,
        'quran_level': quranLevel,
        'doctrine': doctrine,
        'supervisor1_name': supervisorName,
        'supervisor1_relation': supervisorRelation,
        'supervisor1_phone': supervisorPhone,
        'password': password,
        'password_confirmation': confirmPassword,
      };

      if (supervisor2Name != null && supervisor2Name.isNotEmpty) {
        body['supervisor2_name'] = supervisor2Name;
        body['supervisor2_relation'] = supervisor2Relation;
        body['supervisor2_phone'] = supervisor2Phone;
      }

      final response = await apiServices.post("/register", body);

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        final message = response['message'] as String? ?? "";

        if (success) {
          return true;
        } else {
          throw ApiError(
            message: message.isNotEmpty ? message : "فشل عملية التسجيل",
          );
        }
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
  // Check OTP
  // ---------------------------------------------------------------------------
  Future<UserModel?> checkOtp(String phone, String otp) async {
    try {
      final formData = FormData.fromMap({'phone': phone, 'otp': otp});
      final response = await apiServices.postFormData("/check-otp", formData);

      if (response is ApiError) throw response;

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        final data = response['data'];

        if (!success || data == null) {
          throw ApiError(message: response['message'] ?? "رمز التحقق غير صحيح");
        }

        final user = UserModel.fromJson(response);
        if (user.token != null) {
          await PrefHelper.saveToken(user.token!);
        }
        return user;
      }
      throw ApiError(message: "استجابة غير متوقعة");
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
        // حتى لو فشل السيرفر، يفضل مسح التوكن محلياً
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
        // إذا كان الخطأ "الهاتف موجود"، نعيده كـ false (لأنه غير متاح)
        if (response.message.contains('موجود') ||
            response.message.contains('exists')) {
          return false; // الهاتف موجود → غير متاح
        }
        // أخطاء أخرى (شبكة، سيرفر...) نعتبرها "متاح" مؤقتًا لتجنب منع المستخدم
        return true;
      }

      if (response is Map<String, dynamic>) {
        final success = response['success'] as bool? ?? false;
        // إذا كان success == false → الهاتف موجود
        return !success;
      }

      return true; // افتراض أن الهاتف متاح إذا لم نفهم الرد
    } on DioException catch (e) {
      // في حالة خطأ شبكة، نسمح بالاستمرار (لا نمنع المستخدم)
      return true;
    } catch (e) {
      return true;
    }
  }
  // -----
}
