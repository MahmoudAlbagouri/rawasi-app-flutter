// lib/features/auth/views/change_password_view.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/auth/widgets/password_field.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != _newPasswordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isSubmitting = true;
      });
    }

    try {
      final response = await ApiServices().postFormData(
        '/update-password',
        FormData.fromMap({
          'password': _newPasswordController.text,
          'password_confirmation': _confirmPasswordController.text,
        }),
      );

      if (response is Map && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: AppColors.brandPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // مسح الحقول بعد النجاح
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        final message = response is Map && response['message'] != null
            ? response['message']
            : 'حدث خطأ أثناء التحديث';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ في الاتصال'),
          backgroundColor: AppColors.error500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('تغيير كلمة المرور'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'تغيير كلمة المرور',
                  color: AppColors.brandPrimary,
                  size: 24,
                  weight: FontWeight.bold,
                ),
                const Gap(16),

                // كلمة المرور الحالية (اختياري حسب الـ API)
                // PasswordField(
                //   controller: _currentPasswordController,
                //   label: 'كلمة المرور الحالية',
                //   validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
                // ),
                PasswordField(
                  controller: _newPasswordController,
                  label: 'كلمة المرور الجديدة',
                  validator: _validatePassword,
                  enabled: !_isSubmitting,
                ),
                const Gap(16),

                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'تأكيد كلمة المرور',
                  validator: _validateConfirmPassword,
                  enabled: !_isSubmitting,
                ),
                const Gap(24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.lock_open, size: 16),
                    label: _isSubmitting
                        ? const Text('جاري التحديث...')
                        : const Text('تحديث كلمة المرور'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitting
                          ? AppColors.gray300
                          : AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      elevation: _isSubmitting ? 0 : 2,
                      shadowColor: AppColors.brandPrimary.withOpacity(0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
