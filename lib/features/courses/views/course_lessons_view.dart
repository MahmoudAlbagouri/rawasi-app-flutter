// lib/features/courses/views/course_lessons_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
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

  /// Whether to show the "متاح لك مجانًا" notice: only when the free plan
  /// actually withholds part of the course. [total] is the curriculum total
  /// (the number the progress bars show), not the lessons uploaded so far.
  static bool showAllowanceNotice(int? freeLimit, int total) =>
      freeLimit != null && total > freeLimit;

  @override
  State<CourseLessonsView> createState() => _CourseLessonsViewState();
}

class _CourseLessonsViewState extends State<CourseLessonsView> {
  late Future<List<Lesson>> _lessonsFuture;

  bool _paymentStateLoaded = false;

  /// A receipt is waiting for an admin: the paywall then says "under review"
  /// instead of asking the student to pay a second time.
  bool _paymentPending = false;
  bool _freePlanExpired = false;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = CoursesRepo().fetchLessons(widget.courseId);
    _loadPaymentState();
  }

  void _refresh() {
    setState(() {
      _lessonsFuture = CoursesRepo().fetchLessons(widget.courseId);
    });
  }

  Future<void> _loadPaymentState() async {
    try {
      // Exact after returning from the subscription page; cached otherwise.
      final profile = await ProfileRepository().fetchProfile(
        force: _paymentStateLoaded,
      );
      if (!mounted) return;
      final firstLoad = !_paymentStateLoaded;
      _paymentStateLoaded = true;
      setState(() {
        _paymentPending = profile.paymentPending;
        _freePlanExpired = profile.freePlanExpired;
      });
      // Mandatory redirect: opening a course after the 15 days are over goes
      // to the subscriptions page. Only on opening, not after every refresh.
      if (firstLoad) {
        await SubscriptionView.redirectIfFreePlanExpired(context, profile);
        if (mounted) _refresh();
      }
    } catch (_) {
      // Only changes a caption; the lock itself comes from the server.
    }
  }

  /// "اشترك لمتابعة باقي الدروس" -> plans -> receipt -> back here. Whatever
  /// happened there, re-read both the lessons and the payment state: the
  /// server decides what is open, so nothing is assumed on the device.
  Future<void> _openSubscription() async {
    await SubscriptionView.open(context);
    if (!mounted) return;
    _refresh();
    await _loadPaymentState();
  }

  /// Tapping a paywalled lesson: say why (25% of this subject, or the 15
  /// days), then go to the plans.
  Future<void> _onPaywallTap(Lesson lesson) async {
    await SubscriptionView.showPaywall(
      context,
      trialEnded: lesson.isTrialEndedPaywall || _freePlanExpired,
      paymentPending: _paymentPending,
    );
    if (!mounted) return;
    _refresh();
    await _loadPaymentState();
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
                child: CustomText(
                  text: msg,
                  color: AppColors.error600,
                  size: 15,
                ),
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
            final total = widget.progress?.totalLessons ?? lessons.length;
            final trialEnded = lessons.any((l) => l.isTrialEndedPaywall);
            final capped =
                trialEnded ||
                CourseLessonsView.showAllowanceNotice(freeLimit, total);

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              // One extra leading row for the allowance notice.
              itemCount: lessons.length + (capped ? 1 : 0),
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                if (capped && index == 0) {
                  return _freeAllowanceNotice(freeLimit, total, trialEnded);
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
  Widget _freeAllowanceNotice(int? freeLimit, int total, bool trialEnded) {
    final String title;
    final String subtitle;
    if (_paymentPending) {
      title = 'طلب اشتراكك قيد المراجعة';
      subtitle = 'سيُفتح باقي الدروس فور تأكيد الدفع';
    } else if (trialEnded) {
      title = 'انتهت الفترة المجانية (15 يومًا)';
      subtitle = 'اشترك لمتابعة باقي الدروس';
    } else {
      title = 'متاح لك مجانًا: $freeLimit من $total درسًا';
      subtitle = 'اشترك لمتابعة باقي الدروس';
    }

    return GestureDetector(
      onTap: _openSubscription,
      child: Container(
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
                    text: title,
                    color: AppColors.gray900,
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                  const Gap(4),
                  CustomText(
                    text: subtitle,
                    color: AppColors.brandPrimary,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.brandPrimary),
          ],
        ),
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
          // The paywall is the one lock the student can act on: it leads to
          // the plans. An ordinary sequence lock stays inert.
          : lesson.requiresPayment
          ? () => _onPaywallTap(lesson)
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
                          Icon(
                            Icons.replay,
                            size: 16,
                            color: AppColors.brandPrimary,
                          ),
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
                        text: _paymentPending
                            ? 'طلب اشتراكك قيد المراجعة'
                            : 'اشترك لمتابعة باقي الدروس',
                        color: AppColors.warning700,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    )
                  else
                    // The only other reason a lesson is shut: the one before it
                    // is unfinished. It used to say the lesson "may open
                    // automatically later", which was true while a 3-day timer
                    // could open it; nothing does that any more, so saying so
                    // would be a promise the backend will not keep.
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CustomText(
                        text: 'أكمل الدرس السابق لفتح هذا الدرس',
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
