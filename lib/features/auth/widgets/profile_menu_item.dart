// lib/features/profile/widgets/profile_menu_item.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:gap/gap.dart';

class ProfileMenuItem extends StatelessWidget {
  final String title1;
  final String? title2;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool showArrow;

  const ProfileMenuItem({
    super.key,
    required this.title1,
    this.title2,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.brandPrimary).withOpacity(
                      0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.brandPrimary,
                    size: 20,
                  ),
                ),
                Gap(12),
                CustomText(
                  text: title1,
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ],
            ),
            Row(
              children: [
                if (title2 != null)
                  CustomText(text: title2!, size: 14, color: AppColors.gray600),
                if (title2 != null && showArrow) Gap(8),
                if (showArrow)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.gray400,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
