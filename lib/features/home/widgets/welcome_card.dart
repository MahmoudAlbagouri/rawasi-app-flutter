// lib/features/home/widgets/welcome_card.dart
// غير مستخدمة حالياً، ولكنها قد تكون مفيدة في المستقبل
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class WelcomeCard extends StatelessWidget {
  final String name;
  final String dayProgress;
  final double progress;

  const WelcomeCard({
    super.key,
    required this.name,
    required this.dayProgress,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'مرحباً بك، ',
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          color: AppColors.brandSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(6),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${progress.toInt()}%',
                        style: TextStyle(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Gap(8),
                    Text(
                      'اليوم: $dayProgress',
                      style: TextStyle(color: AppColors.gray600, fontSize: 13),
                    ),
                  ],
                ),
                Gap(12),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppColors.gray100,
                  color: AppColors.brandPrimary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          Gap(16),
          Image.asset('assets/images/plant.png', width: 80, height: 80),
        ],
      ),
    );
  }
}
