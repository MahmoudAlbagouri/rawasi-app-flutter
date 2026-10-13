// lib/features/stats/widgets/my_points_card.dart
//
// The student's own points, shown ABOVE the top-ten list and shown ALWAYS.
//
// This used to be MyRankCard: «ترتيبك #N», the points, a weekly rank movement
// and this same breakdown. The rank half was removed on request (2026-10-13) -
// the leaderboard below still ranks the top ten - and the points half stayed,
// so a student who is not in the top ten still sees what they have earned.
//
// Points are one per question solved, new or repeated. The `completed_lessons`
// caption under each name in the list below is not the ranking key, so this
// card leads with points to keep that unambiguous.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class MyPointsCard extends StatelessWidget {
  final Leaderboard board;

  const MyPointsCard({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    // Nothing solved yet: an invitation, never a bare zero or an empty space.
    if (board.myPoints <= 0) return _noPointsYet();

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CustomText(
            text: 'نقاطك',
            color: AppColors.gray600,
            size: 13,
            weight: FontWeight.w600,
          ),
          const Gap(10),
          // The points are the headline figure.
          CustomText(
            text: arabicPoints(board.myPoints),
            color: AppColors.brandPrimary,
            size: 32,
            weight: FontWeight.bold,
          ),
          const Gap(6),
          const CustomText(
            text: 'نقطة لكل سؤال تحله، جديدًا كان أو مكررًا',
            color: AppColors.gray600,
            size: 12,
          ),
          const Gap(12),
          // Where the points come from.
          Row(
            children: [
              Expanded(
                child: _breakdown(
                  icon: Icons.fiber_new_outlined,
                  label: 'أسئلة جديدة',
                  value: arabicQuestions(board.myNewQuestions),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _breakdown(
                  icon: Icons.replay,
                  label: 'أسئلة مكررة',
                  value: arabicQuestions(board.myResolvedQuestions),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdown({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandPrimary, size: 16),
              const Gap(4),
              CustomText(text: label, color: AppColors.gray600, size: 11),
            ],
          ),
          const Gap(4),
          CustomText(
            text: 'حللت $value',
            color: AppColors.gray900,
            size: 13,
            weight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _noPointsYet() {
    return HomeCard(
      child: Row(
        children: [
          const Icon(
            Icons.stars_outlined,
            color: AppColors.gray400,
            size: 30,
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CustomText(
                  text: 'لم تجمع نقاطًا بعد',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                Gap(4),
                CustomText(
                  text: 'ابدأ بحل الأسئلة لتجمع نقاطك',
                  color: AppColors.gray600,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
