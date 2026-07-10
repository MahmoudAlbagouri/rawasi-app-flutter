// lib/features/auth/views/forgot_password/forgot_password_new_password_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';
import 'package:rawasi_app_n/shared/custom-snack.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';

class ForgotPasswordNewPasswordView extends StatefulWidget {
  final String phone;

  const ForgotPasswordNewPasswordView({super.key, required this.phone});

  @override
  State<ForgotPasswordNewPasswordView> createState() =>
      _ForgotPasswordNewPasswordViewState();
}

class _ForgotPasswordNewPasswordViewState
    extends State<ForgotPasswordNewPasswordView> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthRepo _authRepo = AuthRepo();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (pass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(customSnack('الرجاء ملء جميع الحقول'));
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(customSnack('كلمة المرور يجب أن تكون 6 أحرف على الأقل'));
      return;
    }

    if (pass != confirmPass) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(customSnack('كلمة المرور وتأكيدها غير متطابقين'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepo.updateForgetPassword(
        phone: widget.phone,
        password: pass,
        passwordConfirmation: confirmPass,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح!')),
      );

      // العودة إلى شاشة تسجيل الدخول بعد 1.5 ثانية
      await Future.delayed(const Duration(milliseconds: 1500));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      String msg = e is ApiError ? e.message : 'فشل تحديث كلمة المرور';
      ScaffoldMessenger.of(context).showSnackBar(customSnack(msg));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText(
          text: 'كلمة المرور الجديدة',
          color: AppColors.brandPrimary,
          size: 18,
          weight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: 'أدخل كلمة مرور جديدة مؤلفة من 6 أحرف على الأقل.',
                color: AppColors.gray700,
                size: 16,
              ),
              Gap(32),
              CustomTextField(
                hint: 'كلمة المرور الجديدة',
                isPassword: true,
                controller: _passwordController,
              ),
              Gap(16),
              CustomTextField(
                hint: 'تأكيد كلمة المرور',
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              Gap(40),
              CustomElevatedButton(
                text: _isLoading ? 'جاري التحديث...' : 'تحديث كلمة المرور',
                onPressed: _isLoading ? null : _updatePassword,
                backgroundColor: AppColors.brandPrimary,
                textColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
