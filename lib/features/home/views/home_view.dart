// lib/features/home/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/profile/student_profile.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/days/data/day_lesson.dart';
import 'package:rawasi_app_n/features/days/data/days_repo.dart';
import 'package:rawasi_app_n/features/days/widgets/day_card_wrapper.dart';
import 'package:rawasi_app_n/features/home/widgets/daily_progress_card.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:rawasi_app_n/features/lessons/views/lessons_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/day_card.dart';

// ✅ إصلاح روابط الفيديو (إزالة المسافات الزائدة في النهاية)
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
  late Future<StudentAssistantData> _dataFuture;

  final String _inspirationalQuote =
      'وَمَن جَاهَدَ فَإِنَّمَا يُجَاهِدُ لِنَفْسِهِ ';

  // ✅ تحديث نموذج البيانات ليتضمن حالة التسجيل
  Future<StudentAssistantData> _fetchData() async {
    final isSignedIn = await isUserSignedIn();
    StudentProfile? profile;
    DaysResponse? daysResponse;

    if (isSignedIn) {
      try {
        profile = await ProfileRepository().fetchProfile();
      } catch (e) {
        // تجاهل الخطأ في البروفايل
      }

      try {
        daysResponse = await DaysRepo().fetchDailyTasks();
      } catch (e) {
        // تجاهل الخطأ في الأيام
      }
    }

    // ✅ إرجاع حالة التسجيل مع البيانات
    return StudentAssistantData(
      isSignedIn: isSignedIn,
      profile: profile,
      daysResponse: daysResponse,
    );
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: FutureBuilder<StudentAssistantData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // ✅ تحديث القيمة الافتراضية لتشمل حالة التسجيل
              final data =
                  snapshot.data ??
                  StudentAssistantData(
                    isSignedIn: false,
                    profile: null,
                    daysResponse: null,
                  );

              final profile = data.profile;
              final displayName = profile != null
                  ? '${profile.firstName} ${profile.lastName}'
                  : 'مستخدم';
              final currentDay = profile?.currentDay ?? 0;
              final progress = (currentDay / 90.0).clamp(0.0, 1.0);
              final lessons = data.daysResponse?.lessons ?? [];

              return ListView(
                children: [
                  // ✅ 1. بطاقة التقدم اليومي (تمت استعادتها)
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 100),
                    child: DailyProgressCard(
                      name: displayName,
                      progress: progress,
                    ),
                  ),
                  const Gap(24),

                  // ✅ 2. قسم "لمسة إلهام" (تمت استعادته بالكامل)
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

                  // ✅ 3. قسم "رحلة رواسي" (موجود مسبقاً)
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'رؤية رواسي للطالب',
                          color: AppColors.brandPrimary,
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                        const Gap(12),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5,
                            itemBuilder: (context, index) {
                              final isActive = index == 0;
                              return Container(
                                margin: EdgeInsets.only(right: 12),
                                width: 70,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.brandPrimary.withOpacity(0.15)
                                      : AppColors.gray100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.brandPrimary
                                        : AppColors.gray200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getIconForStage(index),
                                      color: isActive
                                          ? AppColors.brandPrimary
                                          : AppColors.gray500,
                                      size: 24,
                                    ),
                                    const Gap(4),
                                    CustomText(
                                      text: _getLabelForStage(index),
                                      color: isActive
                                          ? AppColors.brandPrimary
                                          : AppColors.gray600,
                                      size: 10,
                                      weight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // ✅ 4. الرسالة التحفيزية (موجودة مسبقاً)
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brandPrimary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            color: AppColors.brandPrimary,
                            size: 24,
                          ),
                          const Gap(12),
                          Expanded(
                            child: CustomText(
                              text:
                                  'كل يوم جديد هو فرصة للنمو. استمر، فأنت على الطريق الصحيح.',
                              color: AppColors.gray700,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(24),

                  // ✅ 5. تنبيه الامتحان (موجود مسبقاً)
                  if ([9, 19, 29, 39, 49, 59, 69, 79].contains(currentDay))
                    _AnimatedItem(
                      delay: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warning50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning700,
                            ),
                            const Gap(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: 'هناك امتحان قادم في طريق',
                                    color: AppColors.warning700,
                                    weight: FontWeight.w600,
                                    size: 16,
                                  ),
                                  const Gap(4),
                                  GestureDetector(
                                    onTap: () {},
                                    child: CustomText(
                                      text: 'حدد الموعد الآن',
                                      color: AppColors.warning700,
                                      size: 14,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Gap(24),

                  // ✅ 6. عنوان سجل الدروس اليومي
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomText(
                      text: 'سجل الدروس اليومي',
                      color: AppColors.brandPrimary,
                      size: 18,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const Gap(16),

                  // ✅ 7. الدرس التمهيدي (معدل ليدعم الفيديو المخصص)
                  _AnimatedItem(
                    delay: const Duration(milliseconds: 600),
                    child: DayCard(
                      title: 'الدرس التمهيدي',
                      subtitle: 'تعرف على رواسي',
                      isCompleted: currentDay > 0,
                      showStartButton: true,
                      onPressed: () {
                        // ✅ اختيار رابط الفيديو حسب حالة التسجيل (بدون مسافات زائدة)
                        final videoUrl = data.isSignedIn
                            ? _introVideoSignedIn.trim()
                            : _introVideoNotSignedIn.trim();

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

                  // ✅ 8. الأيام الديناميكية
                  if (lessons.isEmpty &&
                      snapshot.connectionState == ConnectionState.done)
                    const Center(child: Text('لا توجد أيام متاحة')),
                  for (int i = 0; i < lessons.length; i++)
                    _AnimatedItem(
                      delay: Duration(milliseconds: 650 + i * 50),
                      child: DayCardWrapper(
                        lesson: lessons[i],
                        onTap: lessons[i].isTappable
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LessonsView(
                                      dayId: lessons[i].dayNumber,
                                      dayTitle: lessons[i].title,
                                    ),
                                  ),
                                );
                              }
                            : null,
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

  IconData _getIconForStage(int index) {
    switch (index) {
      case 0:
        return Icons.rocket_launch_outlined; // انطلق
      case 1:
        return Icons.menu_book_outlined; // ذاكر
      case 2:
        return Icons.fact_check_outlined; // ثبت
      case 3:
        return Icons.edit_note_outlined; // حل
      case 4:
        return Icons.emoji_events_outlined; // قفّل (القمة)
      default:
        return Icons.circle_outlined;
    }
  }

  String _getLabelForStage(int index) {
    // الكلمات الحماسية (أكشن) مرتبة لتناسب مسار الطالب
    final labels = ['انطلق', 'ذاكر', 'ثبت', 'حل', 'قفّل'];
    return labels[index % labels.length];
  }
}

// ========== نموذج مساعد لجمع البيانات ==========
class StudentAssistantData {
  final bool isSignedIn; // ✅ الإضافة الجديدة
  final StudentProfile? profile;
  final DaysResponse? daysResponse;

  StudentAssistantData({
    required this.isSignedIn,
    required this.profile,
    required this.daysResponse,
  });
}

// ========== Widget مساعد للحركات البسيطة بدون Controller ==========
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
