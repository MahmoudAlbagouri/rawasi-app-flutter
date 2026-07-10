// lib/features/lessons/widgets/lesson_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class LessonCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isVideo;
  final VoidCallback onContinue;

  const LessonCard({
    super.key,
    required this.title,
    required this.content,
    required this.isVideo,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان مع أيقونة نوع المحتوى
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isVideo ? AppColors.primary100 : AppColors.success100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideo ? Icons.play_circle : Icons.quiz,
                  color: isVideo
                      ? AppColors.brandPrimary
                      : AppColors.success600,
                  size: 20,
                ),
              ),
              Gap(12),
              Expanded(
                child: CustomText(
                  text: title,
                  color: AppColors.brandSecondary,
                  size: 16,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gap(8),
          // الوصف
          Text(
            content,
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
          Gap(16),
          // زر الاستمرار
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: 'استمرار',
                    color: AppColors.white,
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
