// lib/features/library/views/subjects_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/views/profile_view.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/features/library/questions_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({super.key});

  @override
  State<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
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
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const CustomText(
          text: 'المكتبة',
          color: AppColors.gray900,
          size: 18,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: FutureBuilder<bool>(
            future: _isSignedInFuture,
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (authSnapshot.data != true) {
                return _buildLoginRequiredScreen();
              }

              return FutureBuilder<Student?>(
                future: _profileFuture,
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

                  return _buildSubjectsList();
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildSubjectsList() {
    return FutureBuilder<List<SubjectItem>>(
      future: LibraryRepo().fetchSubjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: AppColors.error500, size: 60),
                const Gap(16),
                CustomText(
                  text: 'فشل تحميل المواد',
                  color: AppColors.error600,
                  size: 16,
                ),
                const Gap(8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: AppColors.gray600),
                ),
              ],
            ),
          );
        }

        final subjects = snapshot.data ?? [];
        if (subjects.isEmpty) {
          return Center(
            child: CustomText(
              text: 'لا توجد مواد متاحة',
              color: AppColors.gray600,
              size: 16,
            ),
          );
        }

        return ListView.separated(
          itemCount: subjects.length,
          separatorBuilder: (context, index) => const Gap(16),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return _buildSubjectCard(subject);
          },
        );
      },
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
              text: 'قم بإنشاء حسابك الآن للوصول إلى المكتبة.',
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
  Widget _buildPendingReviewScreen(Student? profile) {
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
                    'لقد سجّلت حسابك بنجاح! يرجى رفع إيصال الدفع لتفعيل اشتراكك والوصول إلى المكتبة.',
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

  Widget _buildSubjectCard(SubjectItem subject) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionsView(subjectId: subject.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  subject.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Gap(16),
            Expanded(
              child: CustomText(
                text: subject.name,
                color: AppColors.gray900,
                size: 17,
                weight: FontWeight.w600,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
