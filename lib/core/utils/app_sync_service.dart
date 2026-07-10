// lib/core/services/app_sync_service.dart
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';

class AppSyncService {
  /// يستدعي API مزامنة اليوم المتوقع عند فتح التطبيق (للطلاب المسجلين فقط)
  static Future<void> syncExpectedDayOnAppOpen() async {
    // تحقق مما إذا كان المستخدم مسجل دخوله
    if (!(await isUserSignedIn())) {
      return; // لا تفعل شيئًا إذا لم يكن مسجل دخوله
    }

    try {
      final api = ApiServices();
      // استدعاء الـ API بدون أي بيانات في الـ body
      await api.post('/calculate-expected-current-day', {});

      // لا حاجة لمعالجة الاستجابة لأنها فارغة (حسب طلبك)
      // يمكنك إضافة print للتدقيق أثناء التطوير:
      // print(
      //   '✅ calculate-expected-ءبلارءبلربلبيليبليبلبيليبلبيلببيلcurrent-day synced successfully',
      // );
    } catch (e) {
      // لا تظهر أي خطأ للمستخدم — فقط سجّل الصمت
      // print('❌ بسبيسبيسبسيبسيبSync failed: $e');
    }
  }
}
