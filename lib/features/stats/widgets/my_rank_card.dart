// lib/features/stats/widgets/my_rank_card.dart
//
// The student's own points and rank, shown ABOVE the top-ten list and shown
// ALWAYS.
//
// Previously the rank was appended to the bottom of the leaderboard and only
// when the student was NOT already in the top ten — which suppressed exactly
// the motivating case, seeing "أنت في المركز ٣" for a student who had made it.
//
// Ranking is by POINTS (one per question solved). The `completed_lessons`
// caption under each name in the list below is not the ranking key, so this
// card leads with points to keep that unambiguous.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class MyRankCard extends StatelessWidget {
  final Leaderboard board;

  const MyRankCard({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    final rank = board.myRank;

    // Nothing solved yet: an invitation, never a bare zero or an empty space.
    if (rank == null) return _notRankedYet();

    final inTopTen = board.top.any((e) => e.isCurrentStudent);

    return HomeCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandPrimary, width: 2),
            ),
            alignment: Alignment.center,
            child: CustomText(
              text: '$rank',
              color: AppColors.brandPrimary,
              size: 20,
              weight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'أنت في المركز $rank',
                  color: AppColors.gray900,
                  size: 16,
                  weight: FontWeight.bold,
                ),
                const Gap(4),
                CustomText(
                  text: arabicPoints(board.myPoints),
                  color: AppColors.brandPrimary,
                  size: 14,
                  weight: FontWeight.w600,
                ),
                const Gap(2),
                CustomText(
                  text: inTopTen
                      ? 'ضمن أول عشرة في ${board.scopeLabel}'
                      : 'نقطة لكل سؤال تحله',
                  color: AppColors.gray600,
                  size: 12,
                ),
              ],
            ),
          ),
          if (inTopTen)
            const Icon(Icons.emoji_events, color: Color(0xFFD4AF37), size: 28),
        ],
      ),
    );
  }

  Widget _notRankedYet() {
    return HomeCard(
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: AppColors.gray400,
            size: 30,
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                CustomText(
                  text: 'لم تدخل الترتيب بعد',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                Gap(4),
                CustomText(
                  text: 'ابدأ بحل الأسئلة لدخول الترتيب',
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
