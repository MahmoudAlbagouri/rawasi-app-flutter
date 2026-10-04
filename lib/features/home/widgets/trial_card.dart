// lib/features/home/widgets/trial_card.dart
//
// The student's plan, on home and on إحصائياتي:
//   - FREE: the 15-day trial countdown (`trial` on /analytics).
//   - PAID: the active package — its name and expiry date (`subscription`).
//     A paid student never sees the trial countdown.
//
// Every number and date comes from the server (config/subscription.php,
// Student::subscriptionSummary). Nothing is computed here — a device on a
// different timezone would otherwise disagree with the dashboard.
//
// The trial bar stays in the brand colour all the way down: it used to turn
// warning-orange in the last 5 days, which read as off-brand. The paywall
// itself (SubscriptionView) is where the end of the free plan is explained.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class TrialCard extends StatelessWidget {
  final Trial trial;
  final Subscription subscription;

  const TrialCard({
    super.key,
    required this.trial,
    this.subscription = const Subscription(),
  });

  /// Whether there is anything to show at all.
  static bool hasContent(Trial? trial, Subscription? subscription) =>
      (subscription?.isPaid ?? false) || (trial?.isVisible ?? false);

  @override
  Widget build(BuildContext context) {
    // Paid: the package replaces the trial entirely.
    if (subscription.isPaid) return _active();

    // Not activated yet: no trial is running, so there is nothing to count.
    // The gate banner already explains their situation.
    if (!trial.isVisible) return const SizedBox.shrink();

    return trial.hasEnded ? _ended() : _running();
  }

  /// The active paid package: its name and when it expires.
  Widget _active() {
    final expires = arabicDate(subscription.expiresAt);
    final started = arabicDate(subscription.startedAt);

    return HomeCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primary50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.brandPrimary,
              size: 24,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'اشتراكك مفعّل',
                  color: AppColors.gray600,
                  size: 12,
                  weight: FontWeight.w600,
                ),
                const Gap(2),
                CustomText(
                  text: subscription.planName ?? 'الباقة المدفوعة',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                const Gap(4),
                CustomText(
                  text: expires != null
                      ? 'ينتهي في $expires'
                      : (started != null
                            ? 'مفعّل منذ $started'
                            : 'اشتراك مفعّل'),
                  color: AppColors.brandPrimary,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _running() {
    final remaining = trial.daysRemaining ?? 0;
    final used = trial.daysUsed ?? 0;
    final fraction = trial.totalDays == 0
        ? 0.0
        : (used / trial.totalDays).clamp(0.0, 1.0);

    // The brand colour throughout — no switch to warning-orange near the end.
    const accent = AppColors.brandPrimary;

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
