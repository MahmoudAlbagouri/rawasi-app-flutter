// lib/shared/study_reminder_card.dart
//
// "You haven't studied in N days" — shown on home and on إحصائياتي from one
// widget, so the two cannot drift.
//
// DRIVEN BY delay_days ONLY.
//
// It deliberately knows nothing about lesson unlocking. The 3-day auto-unlock
// in LessonProgressService runs on a DIFFERENT clock — measured from the
// previous lesson's `unlocked_at`, not from the student's last activity — so
// "4 days since you studied" does not imply anything about whether the next
// lesson has opened. Earlier copy here claimed "الدرس التالي مفتوح لك الآن"
// past day 3, which was asserting the state of a clock this card cannot see.
//
// Nothing is lost at day 3 either, so there is no countdown, no deadline and
// no "you will lose access" framing. The card is motivational: it reports
// elapsed time and invites the student back.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

/// Below this, the reminder is not worth showing on home — it would be
/// permanent furniture rather than a nudge.
const int kHomeReminderThreshold = 2;

class StudyReminderCard extends StatelessWidget {
  final Inactivity inactivity;

  /// Opens the next available lesson. Null renders the card without an action.
  final VoidCallback? onContinue;

  /// Home shows a tighter card with a call to action; إحصائياتي shows the
  /// fuller informational version alongside the other stats.
  final bool compact;

  const StudyReminderCard({
    super.key,
    required this.inactivity,
    this.onContinue,
    this.compact = false,
  });

  /// Whether home should show it at all.
  static bool shouldShowOnHome(Inactivity inactivity) {
    final days = inactivity.delayDays;

    return days != null && days >= kHomeReminderThreshold;
  }

  // ---------------------------------------------------------------- copy

  /// Three distinct states: never started, studied today, and N days elapsed.
  String get _headline {
    final days = inactivity.delayDays;

    if (days == null) return 'لم تبدأ بعد';
    if (days == 0) return 'درست اليوم';

    return 'مر ${arabicDays(days)} منذ آخر درس';
  }

  String get _body {
    final days = inactivity.delayDays;

    if (days == null) return 'ابدأ أول درس لتبدأ متابعة تقدمك';
    if (days == 0) return 'واصل التقدم';

    // Encouragement only — nothing expires, so nothing is threatened.
    return 'واصل رحلتك، خطوة صغيرة اليوم تكفي';
  }

  Color get _accent {
    final days = inactivity.delayDays;

    if (days == null) return AppColors.gray500;
    if (days == 0) return AppColors.success600;
    if (days < 3) return AppColors.brandPrimary;

    return AppColors.warning700;
  }

  IconData get _icon {
    final days = inactivity.delayDays;

    if (days == null) return Icons.hourglass_empty;
    if (days == 0) return Icons.check_circle_outline;

    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    final card = HomeCard(
      onTap: onContinue,
      padding: EdgeInsets.all(compact ? 16 : 18),
      child: Row(
        children: [
          Icon(_icon, color: _accent, size: compact ? 26 : 30),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  const CustomText(
                    text: 'أيام الانقطاع عن الدروس الجديدة',
                    color: AppColors.gray900,
                    size: 15,
                    weight: FontWeight.bold,
                  ),
                  const Gap(6),
                ],
                CustomText(
                  text: _headline,
                  color: _accent,
                  size: compact ? 15 : 14,
                  weight: FontWeight.bold,
                ),
                const Gap(2),
                CustomText(
                  text: _body,
                  color: AppColors.gray600,
                  size: 12,
                ),
              ],
            ),
          ),
          if (onContinue != null) ...[
            const Gap(8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.gray400,
            ),
          ],
        ],
      ),
    );

    return card;
  }
}
