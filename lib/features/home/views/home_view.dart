// lib/features/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/courses/views/courses_view.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:rawasi_app_n/features/home/widgets/daily_progress_card.dart';
import 'package:rawasi_app_n/root.dart';
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

  void _goToCoursesOrSubscription(Student? profile) {
    if (profile == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      return;
    }
    if (!profile.isUploadPaidCertificate || !profile.isActive) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionView()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoursesView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
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

                  if (profile != null && !profile.isActive)
                    _AnimatedItem(
                      delay: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.warning700),
                            const Gap(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: !profile.isProfileCompleted
                                        ? 'يرجى استكمال بيانات ملفك الشخصي'
                                        : !profile.isUploadPaidCertificate
                                        ? 'يرجى رفع إيصال الدفع لتفعيل اشتراكك'
                                        : 'حسابك قيد المراجعة من الإدارة',
                                    color: AppColors.warning700,
                                    weight: FontWeight.w600,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }
}

class _HomeData {
  final bool isSignedIn;
  final Student? profile;

  _HomeData({required this.isSignedIn, required this.profile});
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
