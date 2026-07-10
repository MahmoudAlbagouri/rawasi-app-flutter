// lib/features/auth/views/forgot_password/forgot_password_otp_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/views/forget_password/forgot_password_new_password_view.dart';
import 'package:rawasi_app_n/shared/custom-snack.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class ForgotPasswordOtpView extends StatefulWidget {
  final String phone;

  const ForgotPasswordOtpView({super.key, required this.phone});

  @override
  State<ForgotPasswordOtpView> createState() => _ForgotPasswordOtpViewState();
}

class _ForgotPasswordOtpViewState extends State<ForgotPasswordOtpView> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  int _remainingSeconds = 60;
  bool _isCounting = false;
  bool _isLoading = false;

  final AuthRepo _authRepo = AuthRepo();

  @override
  void initState() {
    _controllers = List.generate(4, (index) => TextEditingController());
    _focusNodes = List.generate(4, (index) => FocusNode());
    _startCountdown();
    super.initState();
  }

  void _startCountdown() {
    if (_isCounting) return;

    _isCounting = true;
    _remainingSeconds = 60;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCounting = false;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleResend() async {
    if (!_isCounting) {
      setState(() => _isLoading = true);
      try {
        await _authRepo.sendForgetPasswordOtp(widget.phone);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إعادة إرسال رمز التحقق!')),
        );
        _startCountdown();
      } catch (e) {
        String msg = e is ApiError ? e.message : 'فشل إعادة الإرسال';
        ScaffoldMessenger.of(context).showSnackBar(customSnack(msg));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رمز التحقق المكون من 4 أرقام'),
          backgroundColor: AppColors.error700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepo.checkForgetPasswordOtp(widget.phone, otp);
      // إذا نجح التحقق → انتقل لتحديث كلمة المرور
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordNewPasswordView(phone: widget.phone),
        ),
      );
    } catch (e) {
      String msg = e is ApiError ? e.message : 'رمز التحقق غير صحيح';
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
          text: 'تأكيد الهاتف',
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
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'تم إرسال رمز التحقق إلى '),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(color: AppColors.gray700, fontSize: 17),
                textDirection: TextDirection.rtl,
              ),
              Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.brandPrimary,
                    ),
                    child: const Text('تعديل الرقم'),
                  ),
                  if (_isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.brandPrimary,
                      ),
                      strokeWidth: 2,
                    )
                  else
                    TextButton(
                      onPressed: _isCounting ? null : _handleResend,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: _isCounting
                            ? AppColors.gray400
                            : AppColors.brandPrimary,
                      ),
                      child: Text(
                        _isCounting
                            ? 'إعادة الإرسال (${_remainingSeconds}s)'
                            : 'إعادة الإرسال',
                        style: TextStyle(
                          color: _isCounting
                              ? AppColors.gray400
                              : AppColors.brandPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              Gap(48),
              _buildOTPFields(),
              Gap(40),
              CustomElevatedButton(
                text: _isLoading ? 'جاري التحقق...' : 'تأكيد',
                onPressed: _isLoading ? null : _verifyOtp,
                backgroundColor: AppColors.brandPrimary,
                textColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                horizontalPadding: 24,
                verticalPadding: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPFields() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.gray200, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < 3) {
                    _focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
