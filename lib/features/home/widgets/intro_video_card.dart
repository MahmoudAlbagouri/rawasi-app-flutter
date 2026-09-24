// lib/features/home/widgets/intro_video_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/contact/views/intro_video_view.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

/// Dismissible pointer to the intro video and support.
///
/// Renders whether or not AppConstants.introVideoUrl is set — the destination
/// screen handles the empty case — so the card never links to a dead player.
class IntroVideoCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const IntroVideoCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.ondemand_video_outlined,
                color: AppColors.brandPrimary,
              ),
              const Gap(10),
              const Expanded(
                child: CustomText(
                  text: IntroVideoView.title,
                  color: AppColors.brandPrimary,
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'إخفاء',
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: CustomText(
              text: 'تعرّف على طريقة استخدام التطبيق وكيفية التواصل مع الدعم.',
              color: AppColors.gray700,
              size: 13,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IntroVideoView()),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brandPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'مشاهدة',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
