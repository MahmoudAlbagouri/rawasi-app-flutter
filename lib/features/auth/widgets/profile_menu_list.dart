// lib/features/profile/widgets/profile_menu_list.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/views/change_password_view.dart';
import 'package:rawasi_app_n/features/auth/views/student_details_view.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_menu_item.dart';
import 'package:rawasi_app_n/features/contact/views/contact_view.dart';
import 'package:rawasi_app_n/features/contact/views/intro_video_view.dart';
import 'package:rawasi_app_n/features/contact/views/faq_view.dart';
import 'package:rawasi_app_n/shared/animated_item.dart';
import 'package:rawasi_app_n/shared/app_sounds.dart';

class ProfileMenuList extends StatelessWidget {
  final VoidCallback onLogout;
  const ProfileMenuList({super.key, required this.onLogout});

  // دالة عرض بوب أب تأكيد تسجيل الخروج
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: AppColors.brandPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'هل أنت متأكد؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'سيتم تسجيل خروجك من الحساب. هل ترغب في المتابعة؟',
            style: TextStyle(fontSize: 15, color: AppColors.gray700),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // إغلاق البوب أب
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        color: AppColors.gray800,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // إغلاق البوب أب أولًا
                      onLogout(); // ثم تنفيذ تسجيل الخروج
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'تسجيل الخروج',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
        ProfileMenuItem(
          title1: "بياناتي",
          icon: Icons.badge_outlined,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentDetailsView(),
              ),
            );
          },
        ),
        ProfileMenuItem(
          title1: "الاعدادات و كلمة السر",
          icon: Icons.lock_outline,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChangePasswordView()),
            );
          },
        ),
        ProfileMenuItem(
          title1: "الاشتراك",
          icon: Icons.shield_outlined,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SubscriptionView()),
            );
          },
        ),
        ProfileMenuItem(
          title1: "كيف يعمل التطبيق؟",
          icon: Icons.ondemand_video_outlined,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IntroVideoView()),
            );
          },
        ),
        ProfileMenuItem(
          title1: "تواصل معنا",
          icon: Icons.question_mark,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ContactView()),
            );
          },
        ),
        ProfileMenuItem(
          title1: "الأسئلة الشائعة",
          icon: Icons.help_outline,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FaqView()),
            );
          },
        ),
        const _SoundsSwitchItem(),
        ProfileMenuItem(
          showArrow: false,
          title1: "تسجيل الخروج",
          icon: Icons.logout,
          iconColor: AppColors.brandSecondary,
          onTap: () {
            _showLogoutConfirmationDialog(context);
          },
        ),
    ];

    // The rows arrive with the app's entrance animation, one after another.
    return ListView(
      children: [
        for (var i = 0; i < items.length; i++)
          AnimatedItem(
            delay: Duration(milliseconds: 40 + i * 45),
            child: items[i],
          ),
      ],
    );
  }
}

/// «أصوات التفاعل»: the one switch for the study sounds and the light
/// vibrations that go with them (see AppSounds). Remembered on the device.
class _SoundsSwitchItem extends StatelessWidget {
  const _SoundsSwitchItem();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSounds.enabled,
      builder: (context, on, _) => ProfileMenuItem(
        title1: "أصوات التفاعل",
        icon: on ? Icons.volume_up_outlined : Icons.volume_off_outlined,
        iconColor: AppColors.brandSecondary,
        onTap: () => _set(!on),
        trailing: Switch.adaptive(
          value: on,
          onChanged: _set,
          activeColor: AppColors.brandPrimary,
        ),
      ),
    );
  }

  Future<void> _set(bool on) async {
    await AppSounds.setEnabled(on);
    // Turning it on plays one so the student hears what they chose.
    if (on) AppSounds.play(AppSound.easy);
  }
}
