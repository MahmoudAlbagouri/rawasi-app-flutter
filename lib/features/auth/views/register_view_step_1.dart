// lib/features/auth/views/register_view_step_1.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_2.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep1View extends StatefulWidget {
  const RegisterStep1View({super.key});

  @override
  State<RegisterStep1View> createState() => _RegisterStep1ViewState();
}

class _RegisterStep1ViewState extends State<RegisterStep1View> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController firstName;
  late TextEditingController lastName;
  late TextEditingController mainPhone;
  late TextEditingController secondaryPhone;
  late TextEditingController referralCodeController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCheckingOnSubmit = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    firstName = TextEditingController();
    lastName = TextEditingController();
    mainPhone = TextEditingController();
    secondaryPhone = TextEditingController();
    referralCodeController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstName.dispose();
    lastName.dispose();
    mainPhone.dispose();
    secondaryPhone.dispose();
    referralCodeController.dispose();
    super.dispose();
  }

  Future<bool> _isPhoneExists(String phone) async {
    try {
      final response = await ApiServices().postFormData(
        '/check-phone-exists',
        FormData.fromMap({'phone': phone}),
      );

      if (response is ApiError) {
        return true;
      } else if (response is Map<String, dynamic>) {
        final successValue = response['success'];
        bool isSuccess =
            successValue == true ||
            successValue == 1 ||
            successValue == '1' ||
            successValue.toString().toLowerCase() == 'true';
        return !isSuccess;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال هذا الحقل';
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value)) {
      return 'يجب أن يحتوي الاسم على أحرف فقط';
    }
    return null;
  }

  String? _validatePhone(String? value, {bool isOptional = false}) {
    if (isOptional && (value == null || value.isEmpty)) return null;
    if (value == null || value.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(value)) {
      return 'رقم الهاتف غير صالح (يجب أن يكون 11 رقمًا ويبدأ بـ 010, 011, 012, أو 015)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (value.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String? _validatePasswordMatch(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (value != passwordController.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  void _navigateToStep2(RegistrationData data) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterStep2View(initialData: data),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
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
          scrolledUnderElevation: 0,
          title: CustomText(
            text: 'إنشاء الحساب',
            color: AppColors.brandPrimary,
            size: 18,
            weight: FontWeight.w600,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProgressIndicator(currentStep: 0),
                  Gap(32),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildHeader(),
                        _buildField(
                          title: "الاسم الأول",
                          child: CustomTextField(
                            hint: "ادخل اسمك الأول",
                            isPassword: false,
                            controller: firstName,
                            validator: _validateName,
                          ),
                        ),
                        _buildField(
                          title: "الاسم الأخير",
                          child: CustomTextField(
                            hint: "ادخل اسمك الأخير",
                            isPassword: false,
                            controller: lastName,
                            validator: _validateName,
                          ),
                        ),
                        _buildField(
                          title: "رقم الهاتف (أساسي، واتساب)",
                          child: CustomTextField(
                            hint: "01012345678",
                            isPassword: false,
                            controller: mainPhone,
                            validator: (value) => _validatePhone(value),
                          ),
                        ),
                        _buildField(
                          title: "رقم الهاتف (اختياري)",
                          child: CustomTextField(
                            hint: "01012345678",
                            isPassword: false,
                            controller: secondaryPhone,
                            validator: (value) =>
                                _validatePhone(value, isOptional: true),
                          ),
                        ),
                        _buildField(
                          title: "البريد الإلكتروني",
                          child: CustomTextField(
                            hint: "example@example.com",
                            isPassword: false,
                            controller: emailController,
                            validator: _validateEmail,
                          ),
                        ),
                        // 👇 حقل كود الإحالة (اختياري)
                        _buildField(
                          title: "كود الإحالة (اختياري)",
                          child: CustomTextField(
                            hint: "أدخل كود المسوق إن وُجد",
                            isPassword: false,
                            controller: referralCodeController,
                          ),
                        ),
                        _buildField(
                          title: "كلمة المرور",
                          child: CustomTextField(
                            hint: "أدخل كلمة المرور",
                            isPassword: true,
                            controller: passwordController,
                            validator: _validatePassword,
                          ),
                        ),
                        _buildField(
                          title: "تأكيد كلمة المرور",
                          child: CustomTextField(
                            hint: "أعد إدخال كلمة المرور",
                            isPassword: true,
                            controller: confirmPasswordController,
                            validator: _validatePasswordMatch,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: CustomElevatedButton(
                            text: _isCheckingOnSubmit
                                ? 'جارٍ التحقق...'
                                : 'المتابعة',
                            onPressed: _isCheckingOnSubmit
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate())
                                      return;

                                    final phone = mainPhone.text.trim();

                                    setState(() {
                                      _isCheckingOnSubmit = true;
                                    });

                                    bool phoneExists = await _isPhoneExists(
                                      phone,
                                    );

                                    if (phoneExists) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'لا، هذا الرقم موجود من قبل',
                                            ),
                                            backgroundColor: AppColors.error600,
                                          ),
                                        );
                                        setState(() {
                                          _isCheckingOnSubmit = false;
                                        });
                                      }
                                      return;
                                    }

                                    final data = RegistrationData(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                      confirmPassword: confirmPasswordController
                                          .text
                                          .trim(),
                                      firstName: firstName.text.trim(),
                                      lastName: lastName.text.trim(),
                                      mainPhone: phone,
                                      secondaryPhone:
                                          secondaryPhone.text.trim().isEmpty
                                          ? null
                                          : secondaryPhone.text.trim(),
                                      gender: '',
                                      branch: '',
                                      birthDate: '',
                                      instituteName: '',
                                      governorate: '',
                                      city: '',
                                      supervisorName: '',
                                      supervisorRelation: '',
                                      supervisorPhone: '',
                                      referralCode:
                                          referralCodeController.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : referralCodeController.text.trim(),
                                    );

                                    if (mounted) {
                                      setState(() {
                                        _isCheckingOnSubmit = false;
                                      });
                                      _navigateToStep2(data);
                                    }
                                  },
                            backgroundColor: _isCheckingOnSubmit
                                ? AppColors.gray300
                                : AppColors.brandPrimary,
                            textColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 16),
                            horizontalPadding: 24,
                            verticalPadding: 14,
                          ),
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

  Widget _buildProgressIndicator({required int currentStep}) {
    return Row(
      children: List.generate(4, (index) {
        final bool isCompleted = index < 1;
        final bool isCurrent = index == 1;
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'انضم إلينا! أدخل بياناتك الآن',
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(32),
      ],
    );
  }

  Widget _buildField({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          color: AppColors.gray900,
          size: 15,
          weight: FontWeight.w600,
        ),
        Gap(8),
        child,
        Gap(24),
      ],
    );
  }
}
