// lib/features/home/widgets/library_preview.dart
//
// A short look at the student's saved questions, with a guided empty state.
//
// ORDERING — flagged rather than invented:
// The brief asked for "most recently saved", using LibraryResource.created_at.
// That timestamp is on the per-QUESTION rows (get-library-course-content), not
// on the subject list this section renders: /my-library returns
// LibrarySubjectResource, which carries { id, name, academic_year, madhab,
// term, saved_questions_count } and no timestamp at all. Getting true recency
// would mean either one extra request per subject (N calls to render three
// rows) or a new `latest_saved_at` field on LibrarySubjectResource — a backend
// change this task rules out. So the preview orders by saved count instead,
// which is honest about what the endpoint actually knows. See the note in the
// hand-off for the one-line backend addition that would fix it properly.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

/// Subjects to show before the "عرض الكل" link takes over.
const int kLibraryPreviewCount = 3;

/// Ordered copy of [subjects], capped for the preview.
List<SubjectItem> libraryPreviewOrder(List<SubjectItem> subjects) {
  final sorted = List<SubjectItem>.from(subjects)
    ..sort((a, b) {
      final byCount = b.savedQuestionsCount.compareTo(a.savedQuestionsCount);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });
  return sorted.take(kLibraryPreviewCount).toList();
}

class LibraryPreview extends StatelessWidget {
  final List<SubjectItem> subjects;
  final void Function(SubjectItem subject) onOpenSubject;

  const LibraryPreview({
    super.key,
    required this.subjects,
    required this.onOpenSubject,
  });

  @override
  Widget build(BuildContext context) {
    final shown = libraryPreviewOrder(subjects);

    return HomeCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          for (final s in shown)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onOpenSubject(s),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.secondary50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary100),
                        ),
                        child: const Icon(
                          Icons.bookmark_outline,
                          color: AppColors.brandSecondary,
                          size: 19,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: CustomText(
                          text: s.name,
                          color: AppColors.gray900,
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                      CustomText(
                        text: '${s.savedQuestionsCount} سؤال',
                        color: AppColors.gray600,
                        size: 12,
                      ),
                      const Gap(6),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.gray400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The empty state, which has to teach rather than just say "nothing here".
class LibraryEmptyCard extends StatelessWidget {
  /// Opens a subject so the student can go and save something.
  final VoidCallback onBrowse;

  const LibraryEmptyCard({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.secondary50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.secondary100),
                ),
                child: const Icon(
                  Icons.bookmark_add_outlined,
                  color: AppColors.brandSecondary,
                  size: 24,
                ),
              ),
              const Gap(14),
              const Expanded(
                child: CustomText(
                  text: 'مكتبتك تبدأ من هنا',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(12),
          const CustomText(
            text:
                'احفظ الأسئلة الصعبة أثناء حل الدروس لمراجعتها لاحقًا، ويمكنك استخراجها في ملف PDF.',
            color: AppColors.gray700,
            size: 13,
          ),
          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(
                Icons.play_circle_outline,
                size: 18,
                color: AppColors.brandPrimary,
              ),
              label: const Text(
                'ابدأ درسًا وجرّب الحفظ',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Space-reserving stand-in while /my-library is in flight.
class LibraryPreviewSkeleton extends StatelessWidget {
  const LibraryPreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeCard(
      child: Column(
        children: [
          SkeletonBar(height: 38),
          Gap(12),
          SkeletonBar(height: 38),
        ],
      ),
    );
  }
}
