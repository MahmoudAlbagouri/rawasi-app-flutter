import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

SnackBar customSnack(errorMessage) {
  return SnackBar(
    padding: EdgeInsets.all(10),
    margin: EdgeInsets.only(bottom: 30, right: 20, left: 20),
    elevation: 10,
    behavior: SnackBarBehavior.floating,
    clipBehavior: Clip.none,
    backgroundColor: AppColors.brandError,
    content: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.info, color: Colors.white),
        Gap(10),
        CustomText(
          text: errorMessage,
          color: Colors.white,
          size: 14,
          weight: FontWeight.w600,
        ),
      ],
    ),
  );
}
