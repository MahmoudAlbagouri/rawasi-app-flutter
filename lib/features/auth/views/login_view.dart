// lib/features/auth/views/login_view.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/views/forget_password/forgot_password_phone_view.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_4.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/shared/custom-snack.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late TextEditingController loginController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AuthRepo authRepo = AuthRepo();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loginController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? validateLoginField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني أو رقم الهاتف';
    }

    final trimmed = value.trim();
    final phoneRegex = RegExp(r'^01[0-9]{9}$');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (phoneRegex.hasMatch(trimmed) || emailRegex.hasMatch(trimmed)) {
      return null;
    }

    return 'الرجاء إدخال بريد إلكتروني أو رقم هاتف صحيح (11 رقمًا يبدأ بـ 01)';
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await authRepo.login(
        loginController.text.trim(),
        passwordController.text.trim(),
      );
      if (!mounted) return;

      // free first month: an account that is complete but not yet activated
      // goes to home, which shows the shared "حسابك قيد المراجعة" gate. There
      // is no receipt to upload, so isUploadPaidCertificate is not consulted.
      final Widget destination = user.isProfileCompleted
          ? const HomeView()
          : RegisterStep4View(
              draft: RegistrationDraft(
                RegistrationData(
                  academicYear: user.academicYear,
                  phone1: user.phone1,
                ),
              ),
            );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => destination),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      String errorMessage = "حدث خطأ غير متوقع";
      if (e is ApiError) {
        errorMessage = e.message;
      }
      ScaffoldMessenger.of(context).showSnackBar(customSnack(errorMessage));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تسجيل الدخول',
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك مجدداً!',
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(32),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // حقل "رقم الهاتف أو البريد الإلكتروني"
                        CustomText(
                          text: "رقم الهاتف",
                          color: AppColors.gray900,
                          size: 15,
                          weight: FontWeight.w600,
                        ),
                        Gap(8),
                        CustomTextField(
                          hint: "ادخل رقم الهاتف",
                          isPassword: false,
                          controller: loginController,
                          validator: validateLoginField,
                        ),
                        Gap(20),

                        // حقل كلمة المرور
                        CustomText(
                          text: "كلمة المرور",
                          color: AppColors.gray900,
                          size: 15,
                          weight: FontWeight.w600,
                        ),
                        Gap(8),
                        CustomTextField(
                          hint: "أدخل كلمة المرور",
                          isPassword: true,
                          controller: passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال كلمة المرور';
                            }
                            if (value.length < 6) {
                              return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        Gap(12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordPhoneView(),
                                ),
                              );
                            },
                            child: Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Gap(24),

                        // Login submits the form; "إنشاء حساب جديد" is always
                        // offered beside it, on every pre-auth screen.
                        AuthActions(
                          primary: AuthAction.login,
                          onPrimary: login,
                          isBusy: isLoading,
                          replaceOnNavigate: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
