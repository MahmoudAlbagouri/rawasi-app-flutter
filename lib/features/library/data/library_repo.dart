// lib/features/library/data/library_repo.dart

import 'package:dio/dio.dart'; // مطلوب لـ FormData
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';

class LibraryRepo {
  final ApiServices _apiServices = ApiServices();

  // إضافة سؤال إلى المكتبة
  Future<void> addToLibrary({
    required int courseId,
    required int questionId,
  }) async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final result = await _apiServices.post('/add-to-library', {
      'course_id': courseId.toString(),
      'task_id': questionId.toString(),
      'type': 'question',
    });

    // ApiServices RETURNS an ApiError rather than throwing it, and every refusal
    // from this endpoint is a 422 — so Dio throws, the handler converts, and the
    // result arrives here as an ApiError, not a Map.
    //
    // Without this branch every refusal fell through to the "unexpected
    // response" line below, and the server's actual reason was thrown away:
    // "هذه المهمة قد تمت اضافتها من قبل" and the per-subject full message both
    // reached the student as "استجابة غير متوقعة من الخادم". The caller shows
    // whatever this throws, so this is the only place the message survives.
    if (result is ApiError) throw result;

    if (result is Map<String, dynamic>) {
      if (result['success'] == true) return;
      throw Exception(
        result['message'] as String? ?? 'فشل الإضافة إلى المكتبة',
      );
    } else if (result is String) {
      throw Exception(result);
    }
    throw Exception('استجابة غير متوقعة من الخادم');
  }

  // جلب قائمة المواد (فقه، تفسير، ...)
  Future<List<SubjectItem>> fetchSubjects() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final result = await _apiServices.get('/my-library');

    if (result is Map<String, dynamic> && result['success'] == true) {
      final List<dynamic> dataList = result['data'] ?? [];
      return dataList.map((item) => SubjectItem.fromJson(item)).toList();
    } else if (result is String) {
      throw Exception(result);
    } else {
      throw Exception('حدث خطأ أثناء جلب المواد');
    }
  }

  // جلب محتوى مادة معينة
  Future<List<ContentItem>> fetchContent(int subjectId, String type) async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    final endpoint = '/get-library-course-content/$subjectId?type=$type';
    final result = await _apiServices.get(endpoint);

    if (result is Map<String, dynamic> && result['success'] == true) {
      final List<dynamic> dataList = result['data'] ?? [];
      return dataList.map((item) => ContentItem.fromJson(item)).toList();
    } else if (result is String) {
      throw Exception(result);
    } else {
      throw Exception('حدث خطأ أثناء جلب المحتوى');
    }
  }

  // ✅ دالة حذف عنصر من المكتبة — محسّنة لإظهار أسباب الفشل الحقيقية
  Future<bool> removeFromLibrary({
    required int contentId,
    required int courseId,
    required int taskId,
    required String type,
  }) async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    try {
      final formData = FormData.fromMap({
        'course_id': courseId,
        'task_id': taskId,
        'type': type,
      });

      final result = await _apiServices.deleteFormData(
        '/remove-from-library/$contentId',
        formData,
      );

      // Same ApiError-as-a-value case as addToLibrary above. It matters here
      // too: the full-library message tells the student to delete questions, so
      // a failed delete has to say why rather than "unexpected response".
      if (result is ApiError) throw result;

      // ✅ معالجة الرد من السيرفر بدقة
      if (result is Map<String, dynamic>) {
        if (result['success'] == true) {
          return true;
        } else {
          // ← استخراج رسالة الخطأ الحقيقية من السيرفر
          final message =
              result['message'] as String? ?? 'فشل الحذف من السيرفر';
          throw Exception(message);
        }
      } else if (result is String) {
        // إذا كان الرد نصًا (مثل خطأ شبكة)
        throw Exception(result);
      } else {
        throw Exception('استجابة غير متوقعة من السيرفر');
      }
    } catch (e) {
      // إعادة رمي الاستثناء مع الحفاظ على الرسالة الأصلية
      rethrow;
    }
  }
}
