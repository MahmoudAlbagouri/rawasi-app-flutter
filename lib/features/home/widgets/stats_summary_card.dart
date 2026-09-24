// lib/features/home/widgets/stats_summary_card.dart
//
// The momentum teaser at the top of home: completion, streak, study time and
// one forward-looking figure. Tapping it opens the full إحصائياتي screen.
//
// The completion figure is the CURRICULUM-based one from /analytics, rendered
// through Completion.percentLabel — the same string إحصائياتي prints. Home used
// to show Student.progress instead, which is a different statistic (completed
// questions over every question in the database, unscoped by grade or madhab)
// and is why the two screens disagreed.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class StatsSummaryCard extends StatelessWidget {
  final StudentStats stats;
  final VoidCallback onTap;

  const StatsSummaryCard({
    super.key,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = stats.completion;

    return HomeCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                color: AppColors.brandPrimary,
                size: 22,
              ),
              const Gap(8),
              const Expanded(
                child: CustomText(
                  text: 'إنجازك حتى الآن',
                  color: AppColors.gray900,
                  size: 16,
                  weight: FontWeight.bold,
                ),
              ),
              CustomText(
                text: 'التفاصيل',
                color: AppColors.brandPrimary,
                size: 12,
                weight: FontWeight.w600,
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.brandPrimary,
              ),
            ],
          ),
          const Gap(16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomText(
                text: '${c.percentLabel}%',
                color: AppColors.brandPrimary,
                size: 30,
                weight: FontWeight.bold,
              ),
              const Gap(8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: CustomText(
                  text: 'من المنهج',
                  color: AppColors.gray600,
                  size: 12,
                ),
              ),
              const Spacer(),
              CustomText(
                text: '${c.completedLessons} من ${c.totalLessons}',
                color: AppColors.gray700,
                size: 13,
                weight: FontWeight.w600,
              ),
            ],
          ),
          const Gap(10),
          AnimatedProgressBar(value: c.fraction),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.local_fire_department,
                  tint: AppColors.warning500,
                  value: '${stats.streak.current}',
                  label: 'أيام متتالية',
                ),
              ),
              _divider(),
              Expanded(
                child: _Stat(
                  icon: Icons.timer_outlined,
                  tint: AppColors.brandPrimary,
                  value: stats.timeSpent.label,
                  label: 'مدة المذاكرة',
                  compact: true,
                ),
              ),
              _divider(),
              Expanded(child: _forwardLooking()),
            ],
          ),
          if (_streakNudge != null) ...[
            const Gap(14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomText(
                text: _streakNudge!,
                color: AppColors.warning700,
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: AppColors.gray200,
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );

  /// Whichever forward-looking figure the student can actually act on: the
  /// gap since their last lesson if they have one, otherwise their pace.
  Widget _forwardLooking() {
    final days = stats.inactivity.delayDays;

    if (days != null && days > 0) {
      return _Stat(
        icon: Icons.event_repeat_outlined,
        tint: days >= 3 ? AppColors.warning700 : AppColors.gray600,
        value: '$days',
        label: 'يوم بلا درس',
      );
    }

    return _Stat(
      icon: Icons.speed,
      tint: AppColors.success600,
      value: stats.pacing.lessonsPerWeek <= 0
          ? '—'
          : stats.pacing.lessonsPerWeek.toString(),
      label: 'درس أسبوعياً',
    );
  }

  /// Encouragement only — never framed as something about to be lost.
  String? get _streakNudge {
    final current = stats.streak.current;
    final rank = stats.leaderboard.myRank;

    if (current >= 2) {
      return '🔥 ${arabicDays(current)} متتالية — واصل، أنت في الطريق';
    }
    if (rank != null && rank <= 10) {
      return '⭐ ترتيبك $rank على دفعتك — إنجاز جميل';
    }
    return null;
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String value;
  final String label;
  final bool compact;

  const _Stat({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: tint, size: 20),
        const Gap(6),
        CustomText(
          text: value,
          color: AppColors.gray900,
          size: compact ? 13 : 18,
          weight: FontWeight.bold,
          align: TextAlign.center,
        ),
        const Gap(2),
        CustomText(
          text: label,
          color: AppColors.gray600,
          size: 11,
          align: TextAlign.center,
        ),
      ],
    );
  }
}

/// Shown when /analytics is unavailable.
///
/// The endpoint sits behind CheckStudentActive, but home renders for students
/// who are not activated yet — so a 403 here is expected, not exceptional, and
/// must never surface as an error. It reserves the same vertical space as the
/// real card so nothing jumps when the two states swap.
class StatsSummaryPlaceholder extends StatelessWidget {
  /// True while the request is still in flight (skeleton), false once we know
  /// there is nothing to show (explanatory copy).
  final bool loading;

  const StatsSummaryPlaceholder({super.key, this.loading = false});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const HomeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBar(width: 120, height: 16),
            Gap(18),
            SkeletonBar(width: 90, height: 28),
            Gap(12),
            SkeletonBar(height: 10),
            Gap(20),
            SkeletonBar(height: 34),
          ],
        ),
      );
    }

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: AppColors.gray400, size: 22),
              const Gap(8),
              const CustomText(
                text: 'إنجازك حتى الآن',
                color: AppColors.gray900,
                size: 16,
                weight: FontWeight.bold,
              ),
            ],
          ),
          const Gap(14),
          const CustomText(
            text: 'ستظهر إحصائياتك هنا بمجرد تفعيل حسابك وبدء أول درس.',
            color: AppColors.gray600,
            size: 13,
          ),
          const Gap(16),
          const SkeletonBar(height: 10, animate: false),
        ],
      ),
    );
  }
}
