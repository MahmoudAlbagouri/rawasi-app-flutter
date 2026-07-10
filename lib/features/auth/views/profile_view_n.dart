import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_1.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_menu_item.dart';
import 'package:rawasi_app_n/features/auth/widgets/user_profile_header.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class ProfileViewN extends StatelessWidget {
  const ProfileViewN({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // appBar: AppBar(
      //   backgroundColor:
      //       AppColors.white,
      //   elevation: 0,
      //   title: const Text('حسابي'),
      //   centerTitle: true,
      // ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 30,
            bottom: 16.0,
          ),
          child: Column(
            children: [
              UserProfileHeader(
                initials: "ح",
                fullName: "حسابي",
                username: "يجب عليك التسجيل اولا",
              ),
              Gap(16),
              CustomElevatedButton(
                text: 'تسجيل الدخول',
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  ),
                },
              ),
              CustomElevatedButton(
                text: "انشاء حساب جديد",
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterStep1View(),
                    ),
                  ),
                },
              ),

              Gap(16),
              ProfileMenuItem(
                title1: "الثيم",
                title2: "فاتح",
                icon: Icons.wb_sunny_outlined,
                iconColor: AppColors.brandPrimary,
                onTap: () {
                  // تغيير الثيم
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("تغيير الثيم")));
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        selectedIndex: 4,
      ), // رقم 0 = حسابي
    );
  }
}
