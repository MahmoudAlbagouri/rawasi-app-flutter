// lib/features/days/widgets/login_prompt_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/views/profile_view.dart';

class LoginPromptCard extends StatelessWidget {
  const LoginPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary600, size: 20),
          Gap(8),
          Expanded(
            child: Text(
              'يجب تسجيل الدخول أولاً لاستكمال المواد',
              style: TextStyle(color: AppColors.primary700, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileView()),
              );
            },
            child: Text(
              'سجل الآن',
              style: TextStyle(
                color: AppColors.primary600,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
