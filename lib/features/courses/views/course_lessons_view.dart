// lib/features/courses/views/course_lessons_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/courses_repo.dart';
import 'package:rawasi_app_n/features/courses/data/lesson.dart';
import 'package:rawasi_app_n/features/courses/views/lesson_flow_view.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class CourseLessonsView extends StatefulWidget {
  final int courseId;
  final String courseName;

  /// Curriculum figures for this subject, forwarded to the lesson flow so its
  /// completion summary measures against the full subject rather than the
  /// lessons uploaded so far.
  final CourseProgress? progress;

  const CourseLessonsView({
    super.key,
    required this.courseId,
    required this.courseName,
    this.progress,
  });

  @override
  State<CourseLessonsView> createState() => _CourseLessonsViewState();
}

class _CourseLessonsViewState extends State<CourseLessonsView> {
  late Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = CoursesRepo().fetchLessons(widget.courseId);
  }

  void _refresh() {
    setState(() {
      _lessonsFuture = CoursesRepo().fetchLessons(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.courseName,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Lesson>>(
          future: _lessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final msg = snapshot.error is ApiError
                  ? (snapshot.error as ApiError).message
                  : 'فشل تحميل الدروس';
              return Center(
                child: CustomText(text: msg, color: AppColors.error600, size: 15),
              );
            }
            final lessons = snapshot.data ?? [];
            if (lessons.isEmpty) {
              return Center(
                child: CustomText(
                  text: 'لا توجد دروس متاحة بعد',
                  color: AppColors.gray600,
                  size: 15,
                ),
              );
            }
            // The free-plan allowance, if this student has one. Every lesson
            // carries the same figure, so the first is as good as any.
            final freeLimit = lessons.first.freeLimitLessons;
            final capped = freeLimit != null && lessons.length > freeLimit;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              // One extra leading row for the allowance notice.
              itemCount: lessons.length + (capped ? 1 : 0),
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                if (capped && index == 0) {
                  return _freeAllowanceNotice(freeLimit, lessons.length);
                }

                return _lessonCard(lessons[index - (capped ? 1 : 0)]);
              },
            );
          },
        ),
      ),
    );
  }

  /// How much of this subject the free plan covers.
  ///
  /// Stated once, at the top, as a plain count rather than a percentage: the
  /// student can count the open lessons in the list below and see that the
  /// number is true. A percentage would be a claim they cannot check.
  Widget _freeAllowanceNotice(int freeLimit, int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, color: AppColors.brandPrimary, size: 24),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'متاح لك مجانًا: $freeLimit من $total درسًا',
                  color: AppColors.gray900,
                  size: 14,
                  weight: FontWeight.w600,
                ),
                const Gap(4),
                CustomText(
                  text: 'اشترك لمتابعة باقي دروس المادة',
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

  Widget _lessonCard(Lesson lesson) {
    final Color color = switch (lesson.status) {
      'completed' => AppColors.success600,
      'unlocked' => AppColors.brandPrimary,
      // A paywalled lesson is not a failure state, so it does not take the
      // muted grey of a lesson the student has not earned yet.
      _ => lesson.requiresPayment ? AppColors.warning700 : AppColors.gray500,
    };
    final IconData icon = switch (lesson.status) {
      'completed' => Icons.check_circle,
      'unlocked' => Icons.play_circle_fill,
      _ => lesson.requiresPayment ? Icons.workspace_premium : Icons.lock,
    };

    return GestureDetector(
      onTap: lesson.isUnlocked
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonFlowView(
                    lessonId: lesson.id,
                    courseId: widget.courseId,
                    lessonTitle: lesson.title,
                    courseProgress: widget.progress,
                  ),
                ),
              );
              _refresh();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'الدرس ${lesson.order}: ${lesson.title}',
                    color: AppColors.gray900,
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                  if (lesson.status != 'locked') ...[
                    const Gap(8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: lesson.questionsCount > 0
                            ? lesson.completedQuestionsCount /
                                lesson.questionsCount
                            : 0,
                        color: color,
                        backgroundColor: AppColors.gray200,
                        minHeight: 6,
                      ),
                    ),
                    const Gap(4),
                    CustomText(
                      text:
                          '${lesson.completedQuestionsCount} / ${lesson.questionsCount} سؤال',
                      color: AppColors.gray600,
                      size: 12,
                    ),
                    // A completed lesson can be re-solved any number of times;
                    // repeats are not recorded, so this changes nothing.
                    if (lesson.isCompleted) ...[
                      const Gap(6),
                      Row(
                        children: [
                          Icon(Icons.replay, size: 16, color: AppColors.brandPrimary),
                          const Gap(4),
                          CustomText(
                            text: 'حل مرة أخرى',
                            color: AppColors.brandPrimary,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ],
                    ] else if (lesson.requiresPayment)
                    // The one lock the student can do something about today.
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CustomText(
                        text: 'اشترك لمتابعة باقي الدروس',
                        color: AppColors.warning700,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    )
                  else if (lesson.autoUnlockDeadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CustomText(
                        text: 'مغلق — قد يُفتح تلقائيًا لاحقًا',
                        color: AppColors.gray500,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
