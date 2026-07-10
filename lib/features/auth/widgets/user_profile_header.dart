// lib/features/profile/widgets/user_profile_header.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:gap/gap.dart';

class UserProfileHeader extends StatelessWidget {
  final String initials;
  final String fullName;
  final String username;

  const UserProfileHeader({
    super.key,
    required this.initials,
    required this.fullName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CustomText(
              text: initials,
              size: 32,
              weight: FontWeight.bold,
              color: AppColors.brandPrimary,
            ),
          ),
        ),
        Gap(14),
        CustomText(
          text: fullName,
          size: 19,
          weight: FontWeight.bold,
          color: AppColors.gray900,
        ),
        Gap(4),
        CustomText(text: username, size: 14, color: AppColors.gray600),
      ],
    );
  }
}
