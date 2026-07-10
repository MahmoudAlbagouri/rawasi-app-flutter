// lib/core/repositories/library_repository.dart

import 'package:dio/dio.dart';
import 'package:rawasi_app_n/core/network/api_error.dart'; // ← جديد
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';

class LibraryRepository {
  final ApiServices _apiServices = ApiServices();

  // ... باقي الدوال ...

  Future<void> addToLibrary({
    required String type,
    required int taskId,
    required int courseId,
  }) async {
    print('📡 بدء إضافة إلى المكتبة...');
    print(
      '📦 البيانات المرسلة: { course_id: $courseId, task_id: $taskId, type: $type }',
    );

    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      print('❌ المستخدم غير مسجل الدخول');
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final body = {'course_id': '$courseId', 'task_id': '$taskId', 'type': type};

    try {
      print('📤 إرسال طلب POST إلى /add-to-library...');
      final result = await _apiServices.post('/add-to-library', body);

      // 👇 التعامل مع ApiError
      if (result is ApiError) {
        print('🔴 استلام ApiError: ${result.message}');
        throw Exception(result.message);
      }

      if (result is Map<String, dynamic>) {
        print('✅ الرد من السيرفر: $result');
        if (result['success'] == true) {
          print('🟢 تم الإضافة بنجاح!');
          return;
        } else {
          final msg = result['message'] as String? ?? 'فشل الإضافة إلى المكتبة';
          print('🔴 فشل الإضافة: $msg');
          throw Exception(msg);
        }
      } else if (result is String) {
        print('🔴 الرد كنص: $result');
        throw Exception(result);
      } else {
        print('❓ نوع الرد غير معروف: ${result.runtimeType}');
        throw Exception('رد غير متوقع من الخادم');
      }
    } on DioException catch (e) {
      print('💥 خطأ DioException:');
      print('   - النوع: ${e.type}');
      print('   - رمز الحالة: ${e.response?.statusCode}');
      print('   - الرسالة: ${e.message}');
      print('   - بيانات الرد: ${e.response?.data}');

      if (e.response?.statusCode == 422) {
        final message = e.response?.data is Map
            ? e.response?.data['message']
            : 'المادة موجودة مسبقًا';
        throw Exception(message as String? ?? 'المادة موجودة مسبقًا');
      } else if (e.response?.statusCode == 401) {
        throw Exception('يرجى تسجيل الدخول مرة أخرى');
      } else {
        throw Exception('حدث خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      print('🔥 خطأ عام: $e');
      throw Exception('فشل الإضافة: ${e.toString()}');
    }
  }
}
