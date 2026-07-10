// lib/features/auth/views/forgot_password/forgot_password_phone_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/views/forget_password/forgot_password_otp_view.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';
import 'package:rawasi_app_n/shared/custom-snack.dart';

class ForgotPasswordPhoneView extends StatefulWidget {
  const ForgotPasswordPhoneView({super.key});

  @override
  State<ForgotPasswordPhoneView> createState() =>
      _ForgotPasswordPhoneViewState();
}

class _ForgotPasswordPhoneViewState extends State<ForgotPasswordPhoneView> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthRepo _authRepo = AuthRepo();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(customSnack('الرجاء إدخال رقم الهاتف'));
      return;
    }

    // التحقق من صحة الرقم (اختياري: مثلاً 11 رقمًا يبدأ بـ 01)
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(customSnack('الرجاء إدخال رقم هاتف مصري صحيح'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepo.sendForgetPasswordOtp(phone);
      // إذا نجح → انتقل للشاشة التالية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ForgotPasswordOtpView(phone: phone)),
      );
    } catch (e) {
      String msg = e is ApiError ? e.message : 'فشل إرسال رمز التحقق';
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
          text: 'استرجاع كلمة المرور',
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
                text: 'أدخل رقم هاتفك المسجل وسيتم إرسال رمز التحقق إليه.',
                color: AppColors.gray700,
                size: 16,
              ),
              Gap(32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  labelStyle: TextStyle(color: AppColors.gray500),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.brandPrimary,
                      width: 2,
                    ),
                  ),
                ),
                textDirection: TextDirection.rtl,
              ),
              Gap(40),
              CustomElevatedButton(
                text: _isLoading ? 'جاري الإرسال...' : 'إرسال رمز التحقق',
                onPressed: _isLoading ? null : _sendOtp,
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
