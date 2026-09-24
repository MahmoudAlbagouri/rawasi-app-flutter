// lib/features/library/views/subjects_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/features/library/questions_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
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
    // Both ways in, same shared pair as every other pre-auth surface.
    return const AccountGate(
      reason: GateReason.signedOut,
      action: AuthActions(primary: AuthAction.register),
    );
  }

  /// free first month: this used to show "أكمل اشتراكك الآن" with a link to the
  /// receipt upload whenever is_upload_paid_certificate was false - which
  /// contradicted the courses screen and home for the very same student. There
  /// is no payment step now, so the one remaining blocker is admin activation.
  Widget _buildPendingReviewScreen(Student? profile) {
    return AccountGate(reason: gateFor(profile) ?? GateReason.underReview);
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
