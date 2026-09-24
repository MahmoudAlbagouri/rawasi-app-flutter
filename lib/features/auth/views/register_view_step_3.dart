// lib/features/auth/views/register_view_step_3.dart
//
// Step 3: verify the OTP sent to the phone from step 2. On success the
// account exists (profile incomplete) and we move to completing the profile.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_4.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep3View extends StatefulWidget {
  final RegistrationData registrationData;

  const RegisterStep3View({super.key, required this.registrationData});

  @override
  State<RegisterStep3View> createState() => _RegisterStep3ViewState();
}

class _RegisterStep3ViewState extends State<RegisterStep3View> {
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
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _isCounting = false);
      }
    });
  }

  @override
  void dispose() {
    _isCounting = false;
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _handleResend() async {
    if (_isCounting) return;
    setState(() => _isLoading = true);
    try {
      final data = widget.registrationData;
      await _authRepo.register(
        academicYear: data.academicYear,
        planId: data.planId,
        phone1: data.phone1,
        password: data.password,
        confirmPassword: data.confirmPassword,
        referralCode: data.referralCode,
        code: data.discountCode,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إعادة إرسال رمز التحقق!')),
        );
        _startCountdown();
      }
    } catch (e) {
      final msg = e is ApiError ? e.message : 'فشل إعادة الإرسال';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error600),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      await _authRepo.checkOtp(widget.registrationData.phone1, otp);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              RegisterStep4View(registrationData: widget.registrationData),
        ),
      );
    } catch (e) {
      final msg = e is ApiError ? e.message : 'رمز التحقق غير صحيح';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error600),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFlowPopScope(
      isBusy: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: ProfileFlowAppBar(
            title: 'تأكيد الحساب',
            isBusy: _isLoading,
          ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    final bool isCompleted = index < 3;
                    final bool isCurrent = index == 2;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.brandPrimary
                              : isCurrent
                              ? AppColors.primary300
                              : AppColors.primary100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                Gap(24),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'تم إرسال رمز التحقق إلى '),
                      TextSpan(
                        text: widget.registrationData.phone1,
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
