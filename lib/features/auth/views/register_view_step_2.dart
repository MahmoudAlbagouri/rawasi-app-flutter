// lib/features/auth/register_view_step_2.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_3.dart';
import 'package:rawasi_app_n/features/auth/widgets/build_field.dart';
import 'package:rawasi_app_n/shared/custom_date_field.dart';
import 'package:rawasi_app_n/shared/custom_dropdown.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep2View extends StatefulWidget {
  final RegistrationData initialData;
  const RegisterStep2View({super.key, required this.initialData});

  @override
  State<RegisterStep2View> createState() => _RegisterStep2ViewState();
}

class _RegisterStep2ViewState extends State<RegisterStep2View> {
  final List<Map<String, String>> genders = [
    {'label': 'ذكر', 'value': 'male'},
    {'label': 'أنثى', 'value': 'female'},
  ];
  String? selectedGenderLabel;

  final List<Map<String, String>> branches = [
    {'label': 'علمي', 'value': 'science'},
    {'label': 'أدبي', 'value': 'literature'},
  ];
  String? selectedBranchLabel;

  DateTime? selectedBirthDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _navigateToStep3(RegistrationData data) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterStep3View(initialData: data),
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

  // // ✅ دوال التحقق (validators)
  // String? _validateGender(String? value) {
  //   return value == null ? 'يرجى اختيار الجنس' : null;
  // }

  // String? _validateBranch(String? value) {
  //   return value == null ? 'يرجى اختيار الشعبة' : null;
  // }

  // String? _validateBirthDate(DateTime? date) {
  //   return date == null ? 'يرجى اختيار تاريخ الميلاد' : null;
  // }

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
              // ✅ لا autovalidateMode إطلاقًا — تمامًا مثل step_1
              child: Column(
                children: [
                  // شريط التقدم
                  Row(
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
                  ),
                  Gap(24),
                  Expanded(
                    child: ListView(
                      children: [
                        Text(
                          'انضم إلينا! ادخل بياناتك الآن',
                          style: TextStyle(
                            color: AppColors.gray600,
                            fontSize: 16,
                          ),
                        ),
                        Gap(32),

                        BuildField(
                          title: "الجنس",
                          child: CustomDropdown<String>(
                            hint: 'اختر الجنس',
                            items: genders.map((g) => g['label']!).toList(),
                            itemAsString: (item) => item,
                            value: selectedGenderLabel,
                            onChanged: (value) {
                              setState(() {
                                selectedGenderLabel = value;
                              });
                            },

                            required: true,
                          ),
                        ),
                        Gap(16),

                        BuildField(
                          title: "الشعبة",
                          child: CustomDropdown<String>(
                            hint: 'اختر الشعبة',
                            items: branches.map((b) => b['label']!).toList(),
                            itemAsString: (item) => item,
                            value: selectedBranchLabel,
                            onChanged: (value) {
                              setState(() {
                                selectedBranchLabel = value;
                              });
                            },

                            required: true,
                          ),
                        ),
                        Gap(16),

                        BuildField(
                          title: "تاريخ الميلاد",
                          child: CustomDateField(
                            hint: 'تاريخ الميلاد',
                            selectedDate: selectedBirthDate,
                            onChanged: (date) {
                              setState(() {
                                selectedBirthDate = date;
                              });
                            },

                            required: true,
                          ),
                        ),
                        Gap(24),

                        CustomElevatedButton(
                          text: 'المتابعة',
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            // ✅ التحقق يدوي فقط عند الضغط على الزر
                            if (_formKey.currentState!.validate() &&
                                selectedGenderLabel != null &&
                                selectedBranchLabel != null &&
                                selectedBirthDate != null) {
                              final genderValue = genders
                                  .firstWhere(
                                    (g) => g['label'] == selectedGenderLabel,
                                  )
                                  .values
                                  .elementAt(1);
                              final branchValue = branches
                                  .firstWhere(
                                    (b) => b['label'] == selectedBranchLabel,
                                  )
                                  .values
                                  .elementAt(1);

                              final updatedData = RegistrationData(
                                email: widget.initialData.email,
                                password: widget.initialData.password,
                                confirmPassword:
                                    widget.initialData.confirmPassword,
                                firstName: widget.initialData.firstName,
                                lastName: widget.initialData.lastName,
                                mainPhone: widget.initialData.mainPhone,
                                secondaryPhone:
                                    widget.initialData.secondaryPhone,
                                gender: genderValue,
                                branch: branchValue,
                                birthDate: selectedBirthDate!
                                    .toIso8601String()
                                    .split('T')[0],
                                instituteName: '',
                                governorate: '',
                                city: '',
                                supervisorName: '',
                                supervisorRelation: '',
                                supervisorPhone: '',
                                referralCode: widget
                                    .initialData
                                    .referralCode, // 👈 إضافة هذا السطر
                              );
                              _navigateToStep3(updatedData);
                            }
                          },
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
