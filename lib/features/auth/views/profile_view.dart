// lib/features/profile/profile_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/profile/student_profile.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_menu_list.dart';
import 'package:rawasi_app_n/features/auth/widgets/user_profile_header.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_1.dart';
import 'package:rawasi_app_n/features/contact/views/contact_view.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/root.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthRepo _authRepo = AuthRepo();

  Future<void> _logout(BuildContext context) async {
    try {
      await _authRepo.logout();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تسجيل الخروج: $e')));
    }
  }

  Future<StudentProfile?> _fetchProfile() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) return null;
    try {
      return await ProfileRepository().fetchProfile();
    } catch (e) {
      return null;
    }
  }

  String _getInitials(String? firstName, String? lastName) {
    if (firstName == null && lastName == null) return "ح";
    String first = firstName?.trim().isNotEmpty == true ? firstName![0] : "";
    String last = lastName?.trim().isNotEmpty == true ? lastName![0] : "";
    String initials = "$first$last".toUpperCase();
    return initials.isEmpty ? "ح" : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: FutureBuilder<bool>(
        future: isUserSignedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final isSignedIn = snapshot.data ?? false;

          if (isSignedIn) {
            // جلب بيانات الملف الشخصي
            return FutureBuilder<StudentProfile?>(
              future: _fetchProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profile = profileSnapshot.data;

                final fullName = profile != null
                    ? '${profile.firstName} ${profile.lastName}'
                    : 'مستخدم';
                final username = profile?.phone1 != null
                    ? '@${profile!.phone1}'
                    : '@7657657'; // fallback مؤقت
                final initials = _getInitials(
                  profile?.firstName,
                  profile?.lastName,
                );

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      children: [
                        UserProfileHeader(
                          initials: initials,
                          fullName: fullName,
                          username: username,
                        ),
                        Gap(28),
                        Expanded(
                          child: ProfileMenuList(
                            onLogout: () => _logout(context),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPrimary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactView(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.question_mark,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const UserProfileHeader(
                      initials: "ح",
                      fullName: "حسابي",
                      username: "يجب عليك التسجيل أولًا",
                    ),
                    Gap(24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginView(),
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
                          'تسجيل الدخول',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    Gap(12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterStep1View(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gray300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            color: AppColors.gray800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Gap(24),
                  ],
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 4),
    );
  }
}
