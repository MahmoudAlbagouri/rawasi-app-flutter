// lib/features/auth/views/register_view_step_2.dart
//
// Step 2: phone + password + optional referral/discount code. Calls
// AuthRepo.register() which sends the OTP, then moves to the OTP screen.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/data/auth_repo.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_3.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep2View extends StatefulWidget {
  final RegistrationData initialData;
  const RegisterStep2View({super.key, required this.initialData});

  @override
  State<RegisterStep2View> createState() => _RegisterStep2ViewState();
}

class _RegisterStep2ViewState extends State<RegisterStep2View> {
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  late final TextEditingController referralCodeController;
  late final TextEditingController discountCodeController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthRepo _authRepo = AuthRepo();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    referralCodeController = TextEditingController();
    discountCodeController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    referralCodeController.dispose();
    discountCodeController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال رقم الهاتف';
    if (!RegExp(r'^01[0125][0-9]{8}$').hasMatch(value)) {
      return 'رقم الهاتف غير صالح (11 رقمًا يبدأ بـ 010, 011, 012, أو 015)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء إدخال كلمة المرور';
    if (value.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    return null;
  }

  String? _validatePasswordMatch(String? value) {
    if (value == null || value.isEmpty) return 'الرجاء تأكيد كلمة المرور';
    if (value != passwordController.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedData = widget.initialData.copyWith(
        phone1: phoneController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
        referralCode: referralCodeController.text.trim().isEmpty
            ? null
            : referralCodeController.text.trim(),
        discountCode: discountCodeController.text.trim().isEmpty
            ? null
            : discountCodeController.text.trim(),
      );

      await _authRepo.register(
        academicYear: updatedData.academicYear,
        planId: updatedData.planId,
        phone1: updatedData.phone1,
        password: updatedData.password,
        confirmPassword: updatedData.confirmPassword,
        referralCode: updatedData.referralCode,
        code: updatedData.discountCode,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterStep3View(registrationData: updatedData),
        ),
      );
    } catch (e) {
      final msg = e is ApiError ? e.message : 'حدث خطأ غير متوقع';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFlowPopScope(
      isBusy: _isLoading,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.gray50,
          appBar: ProfileFlowAppBar(
            title: 'إنشاء الحساب',
            isBusy: _isLoading,
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
                    _buildProgressIndicator(),
                    Gap(32),
                    Expanded(
                      child: ListView(
                        children: [
                          CustomText(
                            text: 'بيانات الدخول',
                            color: AppColors.gray600,
                            size: 18,
                            weight: FontWeight.w600,
                          ),
                          Gap(24),
                          _field(
                            'رقم الهاتف (أساسي)',
                            CustomTextField(
                              hint: '01012345678',
                              isPassword: false,
                              controller: phoneController,
                              validator: _validatePhone,
                            ),
                          ),
                          _field(
                            'كلمة المرور',
                            CustomTextField(
                              hint: 'أدخل كلمة المرور',
                              isPassword: true,
                              controller: passwordController,
                              validator: _validatePassword,
                            ),
                          ),
                          _field(
                            'تأكيد كلمة المرور',
                            CustomTextField(
                              hint: 'أعد إدخال كلمة المرور',
                              isPassword: true,
                              controller: confirmPasswordController,
                              validator: _validatePasswordMatch,
                            ),
                          ),
                          _field(
                            'كود الإحالة (اختياري)',
                            CustomTextField(
                              hint: 'أدخل كود المسوق إن وُجد',
                              isPassword: false,
                              controller: referralCodeController,
                            ),
                          ),
                          _field(
                            'كود الخصم (اختياري)',
                            CustomTextField(
                              hint: 'أدخل كود الخصم إن وُجد',
                              isPassword: false,
                              controller: discountCodeController,
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: CustomElevatedButton(
                              text: _isLoading ? 'جارٍ التسجيل...' : 'المتابعة',
                              onPressed: _isLoading ? null : _submit,
                              backgroundColor: _isLoading
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
      ),
    );
  }

  Widget _field(String title, Widget child) {
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

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(5, (index) {
        final bool isCompleted = index < 2;
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
}
