// lib/features/stats/widgets/mastery_card.dart
//
// نسبة الإتقان — how well the OPEN lessons are drilled.
//
// The model, stated on the card so the number is never a mystery: each lesson
// is meant to be solved 5 times. A lesson's mastery is (times solved, max 5)
// / 5, where "solved N times" means every question in it was solved N times —
// the first solve plus every re-solve. The card's
// figure is the average over the open lessons. Computed on the server
// (StudentAnalyticsService::mastery); nothing is derived here.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class MasteryCard extends StatelessWidget {
  final Mastery mastery;

  const MasteryCard({super.key, required this.mastery});

  /// "84%" — whole numbers when there is no fraction to show.
  @visibleForTesting
  static String percentLabel(double value) => value == value.roundToDouble()
      ? '${value.toInt()}%'
      : '${value.toStringAsFixed(1)}%';

  /// The rule, in one sentence the student can check against their own work.
  static String explanation(int target) =>
      'تُحسب نسبة الإتقان على أساس حل كل درس $target مرات. نحسب النسبة لكل درس مفتوح '
      'ثم نأخذ متوسطها، فإذا حللت كل درس مفتوح $target مرات تصل إلى 100%.';

  @override
  Widget build(BuildContext context) {
    final fraction = (mastery.percentage / 100).clamp(0.0, 1.0);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: AppColors.brandPrimary,
                size: 24,
              ),
              const Gap(8),
              const Expanded(
                child: CustomText(
                  text: 'نسبة إتقان الدروس المفتوحة',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
              CustomText(
                text: percentLabel(mastery.percentage),
                color: AppColors.brandPrimary,
                size: 22,
                weight: FontWeight.bold,
              ),
            ],
          ),
          const Gap(12),
          AnimatedProgressBar(
            value: fraction,
            height: 8,
            color: AppColors.brandPrimary,
          ),
          const Gap(8),
          CustomText(
            text: mastery.openLessons == 0
                ? 'لا توجد دروس مفتوحة بعد'
                : 'أتقنت ${arabicLessons(mastery.masteredLessons)} من ${mastery.openLessons} مفتوحة',
            color: AppColors.gray700,
            size: 13,
            weight: FontWeight.w600,
          ),
          const Gap(8),
          CustomText(
            text: explanation(mastery.targetRepetitions),
            color: AppColors.gray600,
            size: 12,
          ),
        ],
      ),
    );
  }
}
