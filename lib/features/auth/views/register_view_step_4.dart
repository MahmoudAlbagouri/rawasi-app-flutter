// lib/features/auth/views/register_view_step_4.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/quran_test/quran_test_screen.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep4View extends StatefulWidget {
  final String phoneNumber;
  final RegistrationData registrationData;

  const RegisterStep4View({
    super.key,
    required this.phoneNumber,
    required this.registrationData,
  });

  @override
  State<RegisterStep4View> createState() => _RegisterStep4ViewState();
}

class _RegisterStep4ViewState extends State<RegisterStep4View> {
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
    if (!_isCounting) {
      setState(() => _isLoading = true);
      try {
        final data = widget.registrationData;
        final success = await _authRepo.register(
          firstName: data.firstName,
          lastName: data.lastName,
          gender: data.gender,
          birthDate: data.birthDate,
          isFinalSecondary: data.branch == 'science',
          schoolBranch: data.branch,
          instituteName: data.instituteName,
          governorate: data.governorate,
          city: data.city,
          phone1: data.mainPhone,
          phone2: data.secondaryPhone,
          isWhatsapp: true,
          email: data.email,
          quranLevel: 'beginner',
          doctrine: 'sunni',
          supervisorName: data.supervisorName,
          supervisorRelation: data.supervisorRelation,
          supervisorPhone: data.supervisorPhone,
          supervisor2Name: data.supervisor2Name,
          supervisor2Relation: data.supervisor2Relation,
          supervisor2Phone: data.supervisor2Phone,
          password: data.password,
          confirmPassword: data.confirmPassword,
          referralCode: data.referralCode,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إعادة إرسال رمز التحقق!')),
          );
          _startCountdown();
        }
      } catch (e) {
        String msg = e is ApiError ? e.message : 'فشل إعادة الإرسال';
        // ✅ عرض رسالة واضحة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error600),
        );
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
      final user = await _authRepo.checkOtp(widget.phoneNumber, otp);
      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const QuranTestScreen()),
          (Route<dynamic> route) =>
              false, // هذه السطر هو المسؤول عن حذف كل الصفحات السابقة
        );
      }
    } catch (e) {
      String msg = e is ApiError ? e.message : 'رمز التحقق غير صحيح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error600),
      );
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
        foregroundColor: AppColors.brandPrimary,
        scrolledUnderElevation: 0,
        title: CustomText(
          text: 'تأكيد الحساب',
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
              Row(
                children: List.generate(4, (index) {
                  final int currentStep = 3;
                  final bool isCompleted = index < currentStep;
                  final bool isCurrent = index == currentStep;
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
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'تم إرسال رمز التحقق إلى '),
                    TextSpan(
                      text: widget.phoneNumber,
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
