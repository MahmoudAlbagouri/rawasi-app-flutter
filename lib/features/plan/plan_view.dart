// lib/features/plan/views/plan_view.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/profile/student_profile.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/views/profile_view.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/plan/semester_plan_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class PlanView extends StatefulWidget {
  const PlanView({super.key});

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  late Future<bool> _isSignedInFuture;
  late Future<StudentProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _isSignedInFuture = isUserSignedIn();
    _profileFuture = _loadProfile();
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
        backgroundColor: AppColors.gray50,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const CustomText(
          text: 'الخطة الدراسية',
          color: AppColors.black,
          size: 18,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _isSignedInFuture,
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (authSnapshot.data != true) {
              return _buildLoginRequiredScreen();
            }

            return FutureBuilder<StudentProfile?>(
              future: _profileFuture,
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = profileSnapshot.data;

                if (profile == null || !profile.isActive) {
                  return _buildPendingReviewScreen(profile); // ← مررنا profile
                }

                return _buildSemesterList();
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildSemesterList() {
    final semesters = List.generate(10, (index) => _getSemesterData(index));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'الابواب الرئيسية',
            style: TextStyle(
              color: AppColors.brandSecondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: semesters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final semester = semesters[index];
                return _buildSemesterCard(context, semester);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: AppColors.gray500),
            const SizedBox(height: 24),
            CustomText(
              text: 'لابد لك من التسجيل أولًا',
              color: AppColors.gray900,
              size: 22,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            CustomText(
              text: 'قم بإنشاء حسابك الآن للوصول إلى الخطة الدراسية الكاملة.',
              color: AppColors.gray700,
              size: 15,
              align: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileView(),
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
                  'التسجيل الآن',
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
              CustomText(
                text: 'أكمل اشتراكك الآن',
                color: AppColors.gray900,
                size: 22,
                weight: FontWeight.bold,
              ),
              const SizedBox(height: 12),
              CustomText(
                text:
                    'لقد سجّلت حسابك بنجاح! يرجى رفع إيصال الدفع لتفعيل اشتراكك والوصول إلى الخطة الدراسية.',
                color: AppColors.gray700,
                size: 15,
                align: TextAlign.center,
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
            CustomText(
              text: 'حسابك قيد المراجعة',
              color: AppColors.gray900,
              size: 22,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 12),
            CustomText(
              text: 'سيتم تفعيل حسابك في أسرع وقت ممكن.',
              color: AppColors.gray700,
              size: 15,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getSemesterData(int index) {
    final semesters = [
      {'title': 'الباب الأول', 'status': 'مفتوح', 'isLocked': false},
      {'title': 'الباب الثاني', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب الثالث', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب الرابع', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب الخامس', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب السادس', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب السابع', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب الثامن', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب التاسع', 'status': 'مغلق', 'isLocked': true},
      {'title': 'الباب العاشر', 'status': 'مغلق', 'isLocked': true},
    ];
    return semesters[index];
  }

  Widget _buildSemesterCard(
    BuildContext context,
    Map<String, dynamic> semester,
  ) {
    return GestureDetector(
      onTap: () {
        if (!semester['isLocked']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SemesterPlanView(semester: semester),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: semester['isLocked'] ? AppColors.gray100 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester['title'],
                    style: TextStyle(
                      color: AppColors.brandSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (!semester['isLocked'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  semester['status'],
                  style: TextStyle(
                    color: AppColors.success700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(Icons.lock, color: AppColors.gray400, size: 24),
          ],
        ),
      ),
    );
  }
}
