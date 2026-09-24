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
import 'package:rawasi_app_n/features/courses/views/course_lessons_view.dart';
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

  @override
  void initState() {
    super.initState();
    _isSignedInFuture = isUserSignedIn();
    _profileFuture = _loadProfile();
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
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildCoursesList() {
    return FutureBuilder<List<Course>>(
      future: CoursesRepo().fetchCourses(),
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
        return ListView.separated(
          itemCount: courses.length,
          separatorBuilder: (context, index) => const Gap(16),
          itemBuilder: (context, index) => _courseCard(courses[index]),
        );
      },
    );
  }

  Widget _courseCard(Course course) {
    final progress = course.progress;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CourseLessonsView(courseId: course.id, courseName: course.name),
          ),
        );
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
                BrandIconBadge(icon: course.icon),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: course.name,
                        color: AppColors.gray900,
                        size: 17,
                        weight: FontWeight.w600,
                      ),
                      if (progress != null) ...[
                        const Gap(6),
                        Row(
                          children: [
                            Icon(Icons.menu_book_outlined, size: 15, color: AppColors.gray500),
                            const Gap(4),
                            CustomText(
                              text: '${progress.totalLessons} درس',
                              color: AppColors.gray600,
                              size: 12,
                            ),
                            const Gap(12),
                            Icon(Icons.check_circle_outline, size: 15, color: AppColors.gray500),
                            const Gap(4),
                            CustomText(
                              text: 'أكملت ${progress.completedLessons}',
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
            if (progress != null) ...[
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
                    text: '${_trimPercent(progress.percentage)}%',
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
                  value: progress.fraction,
                  minHeight: 7,
                  backgroundColor: AppColors.gray200,
                  color: progress.fraction >= 1
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
