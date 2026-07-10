// lib/shared/main_button.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final TextStyle? textStyle;

  const CustomElevatedButton({
    super.key,
    this.onPressed,
    required this.text,
    this.icon,
    this.backgroundColor = AppColors.brandPrimary,
    this.textColor = Colors.white,
    this.borderRadius = 12.0,
    this.horizontalPadding = 24.0,
    this.verticalPadding = 14.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: textStyle ?? TextStyle(fontSize: 16)),
          if (icon != null) ...[Gap(8), icon!],
        ],
      ),
    );
  }
}
