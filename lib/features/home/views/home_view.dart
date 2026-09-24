// lib/features/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_4.dart';
import 'package:rawasi_app_n/features/courses/views/courses_view.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:rawasi_app_n/features/home/widgets/daily_progress_card.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/features/contact/views/intro_video_view.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/day_card.dart';

const String _introVideoNotSignedIn =
    'https://player.mediadelivery.net/embed/556412/ac68484d-d8bb-420e-8119-76deaccb7b75';
const String _introVideoSignedIn =
    'https://player.mediadelivery.net/embed/556412/846d3a20-fd96-4560-97ea-ac097c4d2256';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Future<_HomeData> _dataFuture;

  /// Per-session dismissal of the intro card. Deliberately not persisted and
  /// deliberately not a dialog: it must never block the UI on first launch.
  bool _introDismissed = false;

  final String _inspirationalQuote = 'وَمَن جَاهَدَ فَإِنَّمَا يُجَاهِدُ لِنَفْسِهِ ';

  Future<_HomeData> _fetchData() async {
    final isSignedIn = await isUserSignedIn();
    Student? profile;
    if (isSignedIn) {
      try {
        profile = await ProfileRepository().fetchProfile();
      } catch (_) {}
    }
    return _HomeData(isSignedIn: isSignedIn, profile: profile);
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  void _refresh() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  /// Opens the one step a student can still act on: finishing their profile.
  ///
  /// free first month: there is no payment step any more, so once the profile
  /// is complete there is nothing to open - the account simply waits for an
  /// admin, and the banner says so without being tappable.
  Future<void> _openPendingStep(Student profile) async {
    if (profile.isProfileCompleted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterStep4View(
          draft: RegistrationDraft(
            RegistrationData(
              academicYear: profile.academicYear,
              phone1: profile.phone1,
            ),
          ),
        ),
      ),
    );
    _refresh();
  }

  Future<void> _goToCoursesOrSubscription(Student? profile) async {
    if (profile == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      _refresh();
      return;
    }
    // One shared decision, so courses/library/home cannot disagree.
    if (gateFor(profile) != null) {
      await _openPendingStep(profile);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesView()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: FutureBuilder<_HomeData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  snapshot.data ?? _HomeData(isSignedIn: false, profile: null);
              final profile = data.profile;
              final displayName = profile != null ? profile.fullName : 'ضيف';
              final progress = ((profile?.progress ?? 0) / 100).clamp(0.0, 1.0);

              return ListView(
                children: [
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 100),
                    child: DailyProgressCard(
                      name: displayName,
                      progress: progress,
                      onContinue: () => _goToCoursesOrSubscription(profile),
                    ),
                  ),
                  const Gap(24),
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
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
                                  text: _inspirationalQuote,
                                  color: const Color(0xFF5D1DBB),
                                  size: 15,
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(24),

                  // Signed out: offer both ways in, with the same pair and
                  // hierarchy as every other pre-auth surface.
                  if (!data.isSignedIn) ...[
                    _AnimatedItem(
                      delay: const Duration(milliseconds: 250),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomText(
                              text: 'ابدأ رحلتك مع رواسي',
                              color: AppColors.gray900,
                              size: 16,
                              weight: FontWeight.bold,
                            ),
                            const Gap(4),
                            CustomText(
                              text: 'الشهر الأول مجانًا، بدون أي رسوم.',
                              color: AppColors.gray600,
                              size: 13,
                            ),
                            const Gap(14),
                            const AuthActions(primary: AuthAction.register),
                          ],
                        ),
                      ),
                    ),
                    const Gap(24),
                  ],

                  if (!_introDismissed)
                    _AnimatedItem(
                      delay: const Duration(milliseconds: 280),
                      child: _IntroVideoCard(
                        onDismiss: () =>
                            setState(() => _introDismissed = true),
                      ),
                    ),
                  if (!_introDismissed) const Gap(24),

                  if (profile != null && gateFor(profile) != null)
                    _AnimatedItem(
                      delay: const Duration(milliseconds: 300),
                      child: _PendingStepBanner(
                        profile: profile,
                        onTap: () => _openPendingStep(profile),
                      ),
                    ),
                  const Gap(24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomText(
                      text: 'ابدأ رحلتك التعليمية',
                      color: AppColors.brandPrimary,
                      size: 18,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const Gap(16),

                  _AnimatedItem(
                    delay: const Duration(milliseconds: 400),
                    child: DayCard(
                      title: 'الدرس التمهيدي',
                      subtitle: 'تعرف على رواسي',
                      isCompleted: false,
                      showStartButton: true,
                      onPressed: () {
                        final videoUrl = data.isSignedIn
                            ? _introVideoSignedIn
                            : _introVideoNotSignedIn;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonVideoView(videoUrl: videoUrl),
                          ),
                        );
                      },
                    ),
                  ),
                  const Gap(12),
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 500),
                    child: DayCard(
                      title: 'المواد الدراسية',
                      subtitle: 'تصفح الدروس والأسئلة',
                      isCompleted: false,
                      showStartButton: true,
                      onPressed: () => _goToCoursesOrSubscription(profile),
                    ),
                  ),
                ],
              );
            },
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}

class _HomeData {
  final bool isSignedIn;
  final Student? profile;

  _HomeData({required this.isSignedIn, required this.profile});
}

/// Warns about the next onboarding step the student owes, and opens it on tap.
/// While waiting on admin activation there is nothing to open, so it stays flat.
class _PendingStepBanner extends StatelessWidget {
  final Student profile;
  final VoidCallback onTap;

  const _PendingStepBanner({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // free first month: the only actionable blocker left is an unfinished
    // profile. Everything else is "waiting on the admin", worded exactly as
    // the shared AccountGate and CheckStudentActive word it.
    final bool isActionable = !profile.isProfileCompleted;

    final String title = isActionable
        ? 'يرجى استكمال بيانات ملفك الشخصي'
        : AccountGate.underReviewTitle;

    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning700),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  color: AppColors.warning700,
                  weight: FontWeight.w600,
                  size: 15,
                ),
                const Gap(4),
                CustomText(
                  text: isActionable
                      ? 'اضغط هنا للمتابعة'
                      : AccountGate.underReviewBody,
                  color: AppColors.warning700,
                  size: 13,
                ),
              ],
            ),
          ),
          if (isActionable)
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.warning700,
            ),
        ],
      ),
    );

    final decoration = BoxDecoration(
      color: AppColors.warning50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.warning300),
    );

    if (!isActionable) {
      return Container(decoration: decoration, child: content);
    }

    return Material(
      color: AppColors.warning50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}

/// Dismissible pointer to the intro video and support.
///
/// Renders whether or not AppConstants.introVideoUrl is set - the destination
/// screen handles the empty case - so the card never links to a dead player.
class _IntroVideoCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _IntroVideoCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.ondemand_video_outlined,
                color: AppColors.brandPrimary,
              ),
              const Gap(10),
              Expanded(
                child: CustomText(
                  text: IntroVideoView.title,
                  color: AppColors.brandPrimary,
                  size: 15,
                  weight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'إخفاء',
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18, color: AppColors.gray600),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: CustomText(
              text: 'تعرّف على طريقة استخدام التطبيق وكيفية التواصل مع الدعم.',
              color: AppColors.gray700,
              size: 13,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IntroVideoView()),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brandPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'مشاهدة',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedItem({required this.child, required this.delay});

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
