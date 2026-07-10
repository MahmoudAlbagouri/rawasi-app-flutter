// lib/shared/day_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class DayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool showStartButton;
  final VoidCallback? onPressed;

  const DayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.showStartButton,
    this.onPressed,
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success100
                  : AppColors.brandPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.play_arrow,
              color: isCompleted
                  ? AppColors.success600
                  : AppColors.brandPrimary,
              size: 20,
            ),
          ),
          Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.brandSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(4),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.gray600, fontSize: 14),
                ),
              ],
            ),
          ),
          if (showStartButton)
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'ابدأ الآن',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            )
          else
            Icon(
              isCompleted ? Icons.check_circle : Icons.lock,
              color: isCompleted ? AppColors.success600 : AppColors.gray300,
              size: 24,
            ),
        ],
      ),
    );
  }
}
