// lib/features/days/views/days_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/profile/student_profile.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/views/profile_view.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/days/data/days_repo.dart';
import 'package:rawasi_app_n/features/days/widgets/login_prompt_card.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:rawasi_app_n/features/lessons/views/lessons_view.dart';
import 'package:rawasi_app_n/features/days/widgets/day_card_wrapper.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/day_card.dart';

class DaysView extends StatefulWidget {
  const DaysView({super.key});

  @override
  State<DaysView> createState() => _DaysViewState();
}

class _DaysViewState extends State<DaysView> {
  final DaysRepo _daysRepo = DaysRepo();

  Future<DaysResponse> _fetchLessonsData() async {
    return _daysRepo.fetchDailyTasks();
  }

  Future<StudentProfile?> _loadProfile() async {
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
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'السجل اليومي',
          style: TextStyle(
            color: AppColors.gray800,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: FutureBuilder<bool>(
            future: isUserSignedIn(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final isLoggedIn = authSnapshot.data ?? false;

              if (!isLoggedIn) {
                return _buildNotLoggedInView();
              }

              return FutureBuilder<StudentProfile?>(
                future: _loadProfile(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profile = profileSnapshot.data;

                  if (profile == null || !profile.isActive) {
                    return _buildPendingReviewScreen(
                      profile,
                    ); // ← مررنا profile
                  }

                  return _buildLessonsList();
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildNotLoggedInView() {
    return Column(
      children: [
        const LoginPromptCard(),
        Gap(24),
        Expanded(
          child: ListView(
            children: [
              DayCard(
                title: 'الدرس التمهيدي',
                subtitle: 'تعرف على أساسيات البرنامج',
                isCompleted: false,
                showStartButton: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LessonVideoView(),
                    ),
                  );
                },
              ),
              Gap(16),
              for (int i = 1; i <= 4; i++)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Directionality(
                          textDirection: TextDirection.rtl,
                          child: Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.gray500,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'تسجيل الدخول مطلوب',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'يجب عليك تسجيل الدخول أولاً لفتح هذا اليوم والوصول إلى المحتوى الكامل.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.gray600,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProfileView(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brandPrimary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'تسجيل الدخول',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Column(
                    children: [
                      DayCard(
                        title: 'اليوم $i',
                        subtitle: 'ستفتح هذا اليوم بعد تسجيل الدخول',
                        isCompleted: false,
                        showStartButton: false,
                      ),
                      if (i < 4) Gap(16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 👇 الدالة المعدّلة لتمييز الحالتين
  Widget _buildPendingReviewScreen(StudentProfile? profile) {
    if (profile != null && !profile.isUploadPaidCertificate) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 80, color: AppColors.brandPrimary),
              const SizedBox(height: 24),
              Text(
                'أكمل اشتراكك الآن',
                style: TextStyle(
                  color: AppColors.gray900,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'لقد سجّلت حسابك بنجاح! يرجى رفع إيصال الدفع لتفعيل اشتراكك والوصول إلى السجل اليومي.',
                style: TextStyle(
                  color: AppColors.gray700,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionView(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'الذهاب إلى الاشتراك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: AppColors.warning600),
            const SizedBox(height: 24),
            Text(
              'حسابك قيد المراجعة',
              style: TextStyle(
                color: AppColors.gray900,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'سيتم تفعيل حسابك في أسرع وقت ممكن.',
              style: TextStyle(
                color: AppColors.gray700,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList() {
    return FutureBuilder<DaysResponse>(
      future: _fetchLessonsData(),
      builder: (context, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dataSnapshot.hasError) {
          String errorMessage = dataSnapshot.error is ApiError
              ? dataSnapshot.error.toString()
              : dataSnapshot.error.toString();

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.gray400,
                  size: 48,
                ),
                Gap(12),
                Text(
                  'تعذر تحميل الدروس',
                  style: TextStyle(
                    color: AppColors.gray600,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(6),
                Text(
                  'يرجى المحاولة لاحقًا',
                  style: TextStyle(color: AppColors.gray500),
                ),
                Gap(16),
                OutlinedButton(
                  onPressed: () => setState(() {}),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.brandPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final data = dataSnapshot.data!;
        final lessons = data.lessons;
        final currentDay = data.currentDay;
        final expectedCurrentDay = data.expectedCurrentDay;
        final isOverdue = expectedCurrentDay > currentDay;

        if (lessons.isEmpty) {
          return const Center(child: Text('لا توجد مهام اليوم'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOverdue)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error700),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppColors.error700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'أنت متأخر عن الجدول! يُرجى إكمال اليوم $expectedCurrentDay الآن.',
                        style: TextStyle(
                          color: AppColors.error700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: lessons.length,
                separatorBuilder: (context, index) => Gap(12),
                itemBuilder: (context, index) {
                  final lesson = lessons[index];

                  VoidCallback? onTapCallback = lesson.isTappable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LessonsView(
                                dayId: lesson.dayNumber,
                                dayTitle: lesson.title,
                              ),
                            ),
                          );
                        }
                      : null;

                  return DayCardWrapper(lesson: lesson, onTap: onTapCallback);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
