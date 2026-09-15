// lib/features/home/widgets/daily_progress_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class DailyProgressCard extends StatelessWidget {
  final String name;
  final double progress;
  final VoidCallback onContinue;

  const DailyProgressCard({
    super.key,
    required this.name,
    required this.progress,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'مرحباً بك، $name',
                  color: AppColors.brandSecondary,
                  size: 16,
                  weight: FontWeight.bold,
                ),
                const Gap(6),
                CustomText(
                  text: 'خطوة صغيرة اليوم',
                  color: AppColors.brandPrimary,
                  size: 18,
                  weight: FontWeight.bold,
                ),
                const Gap(2),
                CustomText(
                  text: 'تصنع فارقًا كبيرًا غدًا',
                  color: AppColors.gray600,
                  size: 14,
                ),
                const Gap(16),
                // مؤشر التقدم المحدث — ملئ من اليمين
                CustomLinearProgressWithIndicator(progress: progress),
                const Gap(8),
                // النص تحت الشريط فقط
                Align(
                  alignment: Alignment.center,
                  child: CustomText(
                    text:
                        'تم إنجاز ${((progress * 100).toInt())}% من خطة رواسي',
                    color: AppColors.gray600,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const Gap(16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onContinue,
                      label: const Text('استمرار'),
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      iconAlignment: IconAlignment.end,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Image.asset(
            'assets/images/plant.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// ========== مؤشر تقدم: شريط مملوء من اليمين + دائرة متحركة (من اليمين إلى اليسار) ==========
class CustomLinearProgressWithIndicator extends StatelessWidget {
  final double progress;

  const CustomLinearProgressWithIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final circleRadius = 10.0;
        final circleDiameter = circleRadius * 2;

        // موقع الدائرة: من اليمين إلى اليسار
        final xPos =
            (1 - progress.clamp(0.0, 1.0)) * (trackWidth - circleDiameter);

        // عرض الجزء المملوء من اليمين حتى موقع الدائرة
        final filledWidth = trackWidth - xPos;

        return SizedBox(
          height: 28,
          child: Stack(
            children: [
              // الشريط الخلفي الرمادي (كامل)
              Container(
                height: 6,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // الجزء المملوء بالأزرق — من اليمين حتى موقع الدائرة
              Positioned(
                right: 0, // بدء الملء من اليمين
                top: 8,
                child: Container(
                  width: filledWidth,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // الدائرة الزرقاء (تتحرك من اليمين إلى اليسار)
              Positioned(
                left: xPos,
                top: 0,
                child: Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // ❌ تم حذف النسبة المئوية من هنا
            ],
          ),
        );
      },
    );
  }
}
