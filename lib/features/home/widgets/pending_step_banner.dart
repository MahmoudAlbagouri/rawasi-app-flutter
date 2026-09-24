// lib/features/home/widgets/pending_step_banner.dart
//
// The onboarding blocker banner on home.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

/// Warns about the next onboarding step the student owes, and opens it on tap.
/// While waiting on admin activation there is nothing to open, so it stays flat.
class PendingStepBanner extends StatelessWidget {
  final Student profile;
  final VoidCallback onTap;

  const PendingStepBanner({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // free first month: the only actionable blocker left is an unfinished
    // profile. Everything else is "waiting on the admin", worded exactly as
    // the shared AccountGate and CheckStudentActive word it.
    final bool isActionable = !profile.isProfileCompleted;

    final String title = isActionable
        ? 'يرجى استكمال بيانات ملفك الشخصي'
        : AccountGate.underReviewTitle;

    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning700),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  color: AppColors.warning700,
                  weight: FontWeight.w600,
                  size: 15,
                ),
                const Gap(4),
                CustomText(
                  text: isActionable
                      ? 'اضغط هنا للمتابعة'
                      : AccountGate.underReviewBody,
                  color: AppColors.warning700,
                  size: 13,
                ),
              ],
            ),
          ),
          if (isActionable)
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.warning700,
            ),
        ],
      ),
    );

    final decoration = BoxDecoration(
      color: AppColors.warning50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.warning300),
    );

    if (!isActionable) {
      return Container(decoration: decoration, child: content);
    }

    return Material(
      color: AppColors.warning50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}
