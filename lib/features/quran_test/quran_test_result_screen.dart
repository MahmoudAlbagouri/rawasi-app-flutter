// lib/features/quran_test/quran_test_result_screen.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/quran_test/quran_self_assessment_data.dart';

class QuranTestResultScreen extends StatefulWidget {
  final List<bool?> answers;

  const QuranTestResultScreen({super.key, required this.answers});

  @override
  State<QuranTestResultScreen> createState() => _QuranTestResultScreenState();
}

class _QuranTestResultScreenState extends State<QuranTestResultScreen> {
  bool isLoading = false;
  String? errorMessage;

  Future<void> _sendQuranLevelAndNavigate() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) {
      setState(() {
        errorMessage = 'يرجى تسجيل الدخول أولاً';
      });
      // توجيه المستخدم لصفحة التسجيل تلقائياً بعد 2 ثانية
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionView()),
          (Route<dynamic> route) =>
              false, // هذه السطر هو المسؤول عن حذف كل الصفحات السابقة
        );
      }
      return;
    }

    final knownCount = widget.answers.where((answer) => answer == true).length;
    final apiServices = ApiServices();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await apiServices.post('/detect-quran-level', {
        'correct_answers': knownCount,
      });

      if (response is ApiError) {
        setState(() {
          errorMessage = response.message;
        });
        return;
      }

      // بعد نجاح الإرسال، الانتقال لصفحة الاشتراكات
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionView()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء تحديد المستوى، يرجى المحاولة مرة أخرى';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final knownCount = widget.answers.where((answer) => answer == true).length;
    final totalCount = widget.answers.length;

    String level;
    String levelDescription;
    Color levelColor;

    if (knownCount >= 8) {
      level = 'متميز';
      levelDescription = 'لديك فهم عميق للقرآن وتحفظ جيد للآيات';
      levelColor = AppColors.brandSuccess;
    } else if (knownCount >= 5) {
      level = 'متوسط';
      levelDescription = 'لديك أساس جيد ويمكنك التقدم أكثر بالمذاكرة المنتظمة';
      levelColor = AppColors.brandPrimary;
    } else {
      level = 'مبتدئ';
      levelDescription = 'ابدأ رحلتك مع القرآن الآن وستتفاجأ بتقدمك السريع!';
      levelColor = AppColors.brandWarning;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'نتيجة اختبار تحديد المستوى',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // مؤشر التقدم البصري
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    level,
                    style: TextStyle(
                      color: levelColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // وصف المستوى
              Text(
                levelDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.gray700,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // إحصائية الإجابات
              Text(
                'عدد الآيات التي تعرفها: $knownCount من $totalCount',
                style: TextStyle(
                  color: AppColors.brandSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // مؤشر مرئي للتقدم
              Column(
                children: List.generate(totalCount, (index) {
                  final isCorrect = widget.answers[index] == true;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppColors.brandSuccess
                                : AppColors.gray300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            quranSelfAssessmentItems[index].stem,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCorrect
                                  ? AppColors.gray800
                                  : AppColors.gray500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // زر الاشتراك الرئيسي
              if (!isLoading && errorMessage == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendQuranLevelAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'الاشتراك الآن',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // حالة التحميل
              if (isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.brandPrimary),
                    SizedBox(height: 16),
                    Text(
                      'جاري تحديد مستواك...',
                      style: TextStyle(color: AppColors.gray600),
                    ),
                  ],
                ),

              // رسالة خطأ مع زر إعادة المحاولة
              if (errorMessage != null && !isLoading)
                Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.brandError,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.brandError,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _sendQuranLevelAndNavigate,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.brandPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            color: AppColors.brandPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
