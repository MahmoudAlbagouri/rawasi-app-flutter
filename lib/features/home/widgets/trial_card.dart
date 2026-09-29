// lib/features/home/widgets/trial_card.dart
//
// The free-trial state on home.
//
// Every number comes from the server (`trial` on /analytics, defined in
// config/subscription.php and anchored on students.active_at). Nothing is
// computed here — a device on a different timezone would otherwise disagree
// with the dashboard about which day it is.
//
// NO LOCKOUT FRAMING. Nothing enforces the end of the trial: no middleware
// locks a student out on day 31. So the expired state is informational
// ("انتهت الفترة المجانية") rather than a warning about losing access, and
// there is no negative counter.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class TrialCard extends StatelessWidget {
  final Trial trial;

  const TrialCard({super.key, required this.trial});

  @override
  Widget build(BuildContext context) {
    // Not activated yet: no trial is running, so there is nothing to count.
    // The gate banner already explains their situation.
    if (!trial.isVisible) return const SizedBox.shrink();

    return trial.hasEnded ? _ended() : _running();
  }

  Widget _running() {
    final remaining = trial.daysRemaining ?? 0;
    final used = trial.daysUsed ?? 0;
    final fraction =
        trial.totalDays == 0 ? 0.0 : (used / trial.totalDays).clamp(0.0, 1.0);

    // Gentle at first, warmer as it runs down — but never alarming, because
    // nothing is taken away at the end.
    final accent =
        remaining <= 5 ? AppColors.warning700 : AppColors.brandPrimary;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_outlined, color: accent, size: 22),
              const Gap(8),
              const Expanded(
                child: CustomText(
                  text: 'الفترة المجانية',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
              CustomText(
                text: 'متبقي ${arabicDays(remaining)}',
                color: accent,
                size: 14,
                weight: FontWeight.bold,
              ),
            ],
          ),
          const Gap(12),
          AnimatedProgressBar(value: fraction, height: 7, color: accent),
          const Gap(8),
          Row(
            children: [
              CustomText(
                text: 'استخدمت ${arabicDays(used)} من ${trial.totalDays}',
                color: AppColors.gray600,
                size: 12,
              ),
              const Spacer(),
              if (trial.endsAt != null)
                CustomText(
                  text: 'حتى ${arabicDate(trial.endsAt) ?? ''}',
                  color: AppColors.gray600,
                  size: 12,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Past the window. Informational only — access is unchanged.
  Widget _ended() {
    return HomeCard(
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.brandSecondary,
            size: 22,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'انتهت الفترة المجانية',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                const Gap(4),
                CustomText(
                  text: trial.endsAt != null
                      ? 'انتهت في ${arabicDate(trial.endsAt) ?? ''} — يمكنك متابعة الدراسة كالمعتاد'
                      : 'يمكنك متابعة الدراسة كالمعتاد',
                  color: AppColors.gray600,
                  size: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
