// lib/features/home/widgets/inspiration_card.dart
//
// لمسة إلهام — lifted out of home_view UNCHANGED.
//
// Deliberately not restyled to match the new cards: the calm violet gradient
// and its own typography are the point. It is the one quiet moment on a screen
// that is otherwise all numbers and progress, and the contrast is what makes
// it land. Its hex values stay as literals rather than moving to AppColors
// tokens precisely because it is meant to sit apart from the brand palette.
//
// Only its position in the scroll order changed.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class InspirationCard extends StatelessWidget {
  final String quote;

  const InspirationCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9F3FF), Color(0xFFE6D7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD0B3FF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray200.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF9A4DFF),
              size: 28,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'لمسة إلهام',
                  color: const Color(0xFF7A2FFF),
                  size: 16,
                  weight: FontWeight.bold,
                ),
                const Gap(6),
                CustomText(
                  text: quote,
                  color: const Color(0xFF5D1DBB),
                  size: 15,
                  weight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
