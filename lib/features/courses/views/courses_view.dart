// lib/features/courses/views/courses_view.dart
//
// Home for the Course -> Lesson -> Question flow. Requires an active,
// authenticated student (auth:student + student.active on the backend).

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/courses_repo.dart';
import 'package:rawasi_app_n/features/courses/data/subject_group.dart';
import 'package:rawasi_app_n/features/courses/views/course_lessons_view.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class CoursesView extends StatefulWidget {
  const CoursesView({super.key});

  @override
  State<CoursesView> createState() => _CoursesViewState();
}

class _CoursesViewState extends State<CoursesView> {
  late Future<bool> _isSignedInFuture;
  late Future<Student?> _profileFuture;

  /// Held in state, not built inline.
  ///
  /// This used to be `future: CoursesRepo().fetchCourses()` inside build, which
  /// has both halves of a bug: a brand-new Future on every rebuild, and no way
  /// for anything to ask for a reload. Finishing lessons and coming back left
  /// the old percentages on screen until the tab was rebuilt from scratch,
  /// because returning from a push rebuilds nothing by itself.
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _isSignedInFuture = isUserSignedIn();
    _profileFuture = _loadProfile();
    _coursesFuture = CoursesRepo().fetchCourses();
  }

  /// Re-reads progress from the server.
  ///
  /// Also drops the home cache, because the same figures appear in the subjects
  /// grid there — refreshing one and not the other is how the two screens end
  /// up disagreeing about the same subject.
  Future<void> _reloadCourses() async {
    HomeRepo.invalidate();
    final next = CoursesRepo().fetchCourses();
    setState(() => _coursesFuture = next);
    await next.catchError((_) => <Course>[]);
  }

  Future<Student?> _loadProfile() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) return null;
    try {
      return await ProfileRepository().fetchProfile();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const CustomText(
          text: 'المواد الدراسية',
          color: AppColors.gray900,
          size: 18,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: BrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: FutureBuilder<bool>(
            future: _isSignedInFuture,
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (authSnapshot.data != true) {
                return _buildLoginRequired();
              }
              return FutureBuilder<Student?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // One shared gate: three hand-written branches here used to
                  // contradict the library and home.
                  final reason = gateFor(snapshot.data);
                  if (reason != null) return AccountGate(reason: reason);

                  return _buildCoursesList();
                  },
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(current: NavTab.courses),
    );
  }

  Widget _buildCoursesList() {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: CustomText(
              text: 'فشل تحميل المواد الدراسية',
              color: AppColors.error600,
              size: 15,
            ),
          );
        }
        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return Center(
            child: CustomText(
              text: 'لا توجد مواد دراسية متاحة حاليًا',
              color: AppColors.gray600,
              size: 15,
            ),
          );
        }

        // Grades 1-2 are returned both terms of every subject, so the raw
        // list shows each subject twice. Collapse to one card per subject —
        // the same grouping the home grid uses.
        final subjects = groupCoursesBySubject(courses);

        // Pull-to-refresh as well as the automatic reload: the automatic one
        // covers lessons finished through this screen, this covers progress
        // made anywhere else.
        return RefreshIndicator(
          onRefresh: _reloadCourses,
          child: ListView.separated(
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const Gap(16),
            itemBuilder: (context, index) => _subjectCard(subjects[index]),
          ),
        );
      },
    );
  }

  Widget _subjectCard(SubjectGroup subject) {
    final course = subject.target;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CourseLessonsView(
                  courseId: course.id,
                  courseName: subject.name,
                  progress: course.progress,
                ),
          ),
        );
        // Lessons were very likely completed in there, so the percentages on
        // this screen are stale the moment we come back.
        if (mounted) await _reloadCourses();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BrandIconBadge(icon: subject.icon),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: subject.name,
                        color: AppColors.gray900,
                        size: 17,
                        weight: FontWeight.w600,
                      ),
                      if (subject.hasProgress) ...[
                        const Gap(6),
                        Row(
                          children: [
                            Icon(Icons.menu_book_outlined, size: 15, color: AppColors.gray500),
                            const Gap(4),
                            CustomText(
                              text: '${subject.totalLessons} درس',
                              color: AppColors.gray600,
                              size: 12,
                            ),
                            const Gap(12),
                            Icon(Icons.check_circle_outline, size: 15, color: AppColors.gray500),
                            const Gap(4),
                            CustomText(
                              text: 'أكملت ${subject.completedLessons}',
                              color: AppColors.gray600,
                              size: 12,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
              ],
            ),
            if (subject.hasProgress) ...[
              const Gap(14),
              Row(
                children: [
                  CustomText(
                    text: 'التقدم',
                    color: AppColors.gray700,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                  const Spacer(),
                  CustomText(
                    text: '${_trimPercent(subject.percentage)}%',
                    color: AppColors.gray900,
                    size: 13,
                    weight: FontWeight.bold,
                  ),
                ],
              ),
              const Gap(6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: subject.fraction,
                  minHeight: 7,
                  backgroundColor: AppColors.gray200,
                  color: subject.fraction >= 1
                      ? AppColors.success600
                      : AppColors.brandPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 40.0 → "40", 2.6 → "2.6".
  String _trimPercent(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildLoginRequired() {
    // Both ways in, same hierarchy as every other pre-auth surface.
    return const AccountGate(
      reason: GateReason.signedOut,
      action: AuthActions(),
    );
  }
}
