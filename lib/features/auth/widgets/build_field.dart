import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class BuildField
    extends StatelessWidget {
  const BuildField({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          color: AppColors.gray900,
          size: 16,
          weight: FontWeight.w600,
        ),
        Gap(2),
        child,
        Gap(32),
      ],
    );
  }
}
