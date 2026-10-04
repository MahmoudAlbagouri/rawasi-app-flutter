// lib/features/home/widgets/subjects_grid.dart
//
// The subjects grid: one card per subject, straight into that subject's
// lessons. Replaces the old flat "المواد الدراسية → ابدأ الآن" row.
//
// Two things this has to reconcile:
//
// 1. Grades 1–2 see BOTH terms since term scoping was dropped, so /courses
//    returns e.g. التفسير|1 and التفسير|2. Ten near-identical cards would be
//    noise, so courses are grouped by name into one card per subject.
//
// 2. Per-course `total_lessons` is the SUBJECT's full curriculum total, not
//    that term's share — so التفسير|1 and التفسير|2 both report 39. Summing
//    them would double the denominator. The aggregate therefore comes from
//    /analytics `subjects[]`, which is the real per-subject figure, matched to
//    the course by name (config/curriculum.php `label` is the course name).
//
// When analytics is unavailable the cards still render, just without numbers —
// the grid degrades rather than disappearing.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/subject_group.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class SubjectsGrid extends StatelessWidget {
  final List<SubjectGroup> tiles;
  final void Function(Course course) onOpen;

  const SubjectsGrid({super.key, required this.tiles, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two up on a phone, more as the window grows.
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final t in tiles)
              SizedBox(
                width: width,
                child: _SubjectCard(tile: t, onOpen: onOpen),
              ),
          ],
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectGroup tile;
  final void Function(Course course) onOpen;

  const _SubjectCard({required this.tile, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final count = tile.countLabel;

    return HomeCard(
      padding: const EdgeInsets.all(14),
      onTap: () => onOpen(tile.target),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The tinted container treatment used on the courses screen.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary100),
            ),
            child: Icon(tile.icon, color: AppColors.brandPrimary, size: 22),
          ),
          const Gap(12),
          CustomText(
            text: tile.name,
            color: AppColors.gray900,
            size: 14,
            weight: FontWeight.w600,
            maxLines: 2,
          ),
          const Gap(10),
          if (count != null) ...[
            AnimatedProgressBar(value: tile.fraction, height: 6),
            const Gap(6),
            CustomText(text: count, color: AppColors.gray600, size: 11),
          ] else
            // Analytics unavailable: the card still opens the subject, it just
            // carries no figures.
            const CustomText(
              text: 'ابدأ الدراسة',
              color: AppColors.brandPrimary,
              size: 11,
              weight: FontWeight.w600,
            ),
        ],
      ),
    );
  }
}

/// Space-reserving stand-in while /courses is in flight.
class SubjectsGridSkeleton extends StatelessWidget {
  const SubjectsGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            4,
            (_) => SizedBox(
              width: width,
              child: const HomeCard(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBar(width: 44, height: 44),
                    Gap(12),
                    SkeletonBar(width: 80, height: 12),
                    Gap(14),
                    SkeletonBar(height: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
