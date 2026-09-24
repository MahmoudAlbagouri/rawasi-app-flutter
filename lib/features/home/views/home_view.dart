// lib/features/home/views/home_view.dart
//
// Home: composition and data loading only. Every section lives in its own
// widget under features/home/widgets/.
//
// Order — momentum first, then a study action within one scroll:
//   stats summary → لمسة إلهام → subjects grid → library
//
// The completion figure here is the curriculum-based one from /analytics,
// rendered through Completion.percentLabel, which is the exact string
// إحصائياتي prints. It used to be Student.progress, which is a different
// statistic altogether — completed questions over Question::count(), i.e.
// every question in the database, unscoped by grade or madhab — so the two
// screens could never have agreed.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_4.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/views/course_lessons_view.dart';
import 'package:rawasi_app_n/features/courses/views/courses_view.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';
import 'package:rawasi_app_n/features/home/widgets/animated_item.dart';
import 'package:rawasi_app_n/features/home/widgets/inspiration_card.dart';
import 'package:rawasi_app_n/features/home/widgets/intro_video_card.dart';
import 'package:rawasi_app_n/features/home/widgets/pending_step_banner.dart';
import 'package:rawasi_app_n/features/home/widgets/library_preview.dart';
import 'package:rawasi_app_n/features/home/widgets/stats_summary_card.dart';
import 'package:rawasi_app_n/features/home/widgets/subjects_grid.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/library/questions_view.dart';
import 'package:rawasi_app_n/features/library/subjects_view.dart';
import 'package:rawasi_app_n/features/stats/views/statistics_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Future<HomeData> _dataFuture;

  /// Per-session dismissal of the intro card. Deliberately not persisted and
  /// deliberately not a dialog: it must never block the UI on first launch.
  bool _introDismissed = false;

  static const String _inspirationalQuote =
      'وَمَن جَاهَدَ فَإِنَّمَا يُجَاهِدُ لِنَفْسِهِ ';

  @override
  void initState() {
    super.initState();
    _dataFuture = HomeRepo().load();
  }

  void _refresh({bool force = true}) {
    if (force) HomeRepo.invalidate();
    setState(() => _dataFuture = HomeRepo().load(force: force));
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    // Anything opened from home can change progress, so the cache is dropped.
    _refresh();
  }

  /// Opens the one step a student can still act on: finishing their profile.
  ///
  /// free first month: there is no payment step, so once the profile is
  /// complete there is nothing to open — the account waits for an admin.
  Future<void> _openPendingStep(Student profile) async {
    if (profile.isProfileCompleted) return;

    await _open(RegisterStep4View(
      draft: RegistrationDraft(
        RegistrationData(
          academicYear: profile.academicYear,
          phone1: profile.phone1,
        ),
      ),
    ));
  }

  /// Straight into a subject's lessons — the whole point of the grid is fewer
  /// taps between opening the app and studying.
  Future<void> _openSubject(Course course) => _open(
        CourseLessonsView(courseId: course.id, courseName: course.name),
      );

  Future<void> _openCourses(Student? profile) async {
    if (profile == null) return _open(const LoginView());
    if (gateFor(profile) != null) return _openPendingStep(profile);
    await _open(const CoursesView());
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BrandBackdrop(
        child: SafeArea(
          child: FutureBuilder<HomeData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              final data = snapshot.data ?? HomeData.signedOut();

              return RefreshIndicator(
                onRefresh: () async {
                  HomeRepo.invalidate();
                  final next = HomeRepo().load(force: true);
                  setState(() => _dataFuture = next);
                  await next;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  children: _sections(data, loading),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }

  List<Widget> _sections(HomeData data, bool loading) {
    final profile = data.profile;
    final name = profile?.fullName.trim();

    return [
      _Greeting(name: (name == null || name.isEmpty) ? 'ضيف' : name),
      const Gap(18),

      // 1. Momentum first.
      _animated(100, _statsSection(data, loading)),
      const Gap(22),

      // 2. The one quiet moment on the screen — unchanged, just moved.
      _animated(180, const InspirationCard(quote: _inspirationalQuote)),
      const Gap(22),

      // Signed out: both ways in, same pair as every other pre-auth surface.
      if (!data.isSignedIn) ...[
        _animated(
          240,
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                CustomText(
                  text: 'ابدأ رحلتك مع رواسي',
                  color: AppColors.gray900,
                  size: 16,
                  weight: FontWeight.bold,
                ),
                Gap(4),
                CustomText(
                  text: 'الشهر الأول مجانًا، بدون أي رسوم.',
                  color: AppColors.gray600,
                  size: 13,
                ),
                Gap(14),
                AuthActions(primary: AuthAction.register),
              ],
            ),
          ),
        ),
        const Gap(22),
      ],

      if (profile != null && gateFor(profile) != null) ...[
        _animated(
          260,
          PendingStepBanner(
            profile: profile,
            onTap: () => _openPendingStep(profile),
          ),
        ),
        const Gap(22),
      ],

      // 3. A study action within the first scroll.
      ..._subjectsSection(data, loading),

      // 4. Library.
      ..._librarySection(data, loading),

      if (!_introDismissed) ...[
        _animated(
          420,
          IntroVideoCard(onDismiss: () => setState(() => _introDismissed = true)),
        ),
        const Gap(8),
      ],
    ];
  }

  // -------------------------------------------------------------- sections

  Widget _statsSection(HomeData data, bool loading) {
    final stats = data.stats;

    // No stats is the normal state for a student awaiting activation, since
    // /analytics sits behind CheckStudentActive. Placeholder, never an error.
    if (stats == null) {
      return StatsSummaryPlaceholder(loading: loading);
    }

    return StatsSummaryCard(
      stats: stats,
      onTap: () => _open(const StatisticsView()),
    );
  }

  List<Widget> _subjectsSection(HomeData data, bool loading) {
    final courses = data.courses;

    if (loading && courses == null) {
      return [
        const HomeSectionTitle(title: 'المواد الدراسية'),
        const Gap(12),
        const SubjectsGridSkeleton(),
        const Gap(22),
      ];
    }

    // Nothing to show and nothing to teach — the gate banner above already
    // explains why, so an empty subjects block would just repeat it.
    if (courses == null || courses.isEmpty) return const [];

    final tiles = buildSubjectTiles(courses, data.stats?.subjects ?? const []);

    return [
      HomeSectionTitle(
        title: 'المواد الدراسية',
        actionLabel: 'عرض الكل',
        onAction: () => _openCourses(data.profile),
      ),
      const Gap(12),
      _animated(300, SubjectsGrid(tiles: tiles, onOpen: _openSubject)),
      const Gap(22),
    ];
  }

  List<Widget> _librarySection(HomeData data, bool loading) {
    final library = data.library;

    if (loading && library == null) {
      return [
        const HomeSectionTitle(title: 'مكتبتي'),
        const Gap(12),
        const LibraryPreviewSkeleton(),
        const Gap(22),
      ];
    }

    // Only offered once the student can actually reach the library.
    if (library == null) return const [];

    final hasCourses = (data.courses ?? const []).isNotEmpty;

    return [
      HomeSectionTitle(
        title: 'مكتبتي',
        actionLabel: library.isEmpty ? null : 'عرض الكل',
        onAction: library.isEmpty ? null : () => _open(const SubjectsView()),
      ),
      const Gap(12),
      _animated(
        360,
        library.isEmpty
            ? LibraryEmptyCard(
                onBrowse: () {
                  final courses = data.courses;
                  if (hasCourses) {
                    _openSubject(courses!.first);
                  } else {
                    _openCourses(data.profile);
                  }
                },
              )
            : LibraryPreview(
                subjects: library,
                onOpenSubject: (SubjectItem s) => _open(
                  QuestionsView(subjectId: s.id, subjectName: s.name),
                ),
              ),
      ),
      const Gap(22),
    ];
  }

  Widget _animated(int delayMs, Widget child) => AnimatedItem(
        delay: Duration(milliseconds: delayMs),
        child: child,
      );
}

// -----------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  final String name;

  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: 'مرحباً بك، $name',
          color: AppColors.brandSecondary,
          size: 16,
          weight: FontWeight.bold,
        ),
        const Gap(4),
        const CustomText(
          text: 'خطوة صغيرة اليوم تصنع فارقًا كبيرًا غدًا',
          color: AppColors.gray600,
          size: 13,
        ),
      ],
    );
  }
}
