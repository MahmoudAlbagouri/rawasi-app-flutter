// lib/features/auth/views/register_view_step_4.dart
//
// Complete-profile part A: name, gender, birth date, school branch/final-year
// flag, madhab and term level. Carried forward to part B before the API call.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_5.dart';
import 'package:rawasi_app_n/features/auth/widgets/build_field.dart';
import 'package:rawasi_app_n/shared/custom_date_field.dart';
import 'package:rawasi_app_n/shared/custom_dropdown.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep4View extends StatefulWidget {
  final RegistrationData registrationData;
  const RegisterStep4View({super.key, required this.registrationData});

  @override
  State<RegisterStep4View> createState() => _RegisterStep4ViewState();
}

class _RegisterStep4ViewState extends State<RegisterStep4View> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

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

  final List<Map<String, String>> madhabs = [
    {'label': 'حنفي', 'value': 'hanafi'},
    {'label': 'مالكي', 'value': 'maliki'},
    {'label': 'شافعي', 'value': 'shafii'},
    {'label': 'حنبلي', 'value': 'hanbali'},
  ];
  String? selectedMadhabLabel;

  final List<Map<String, String>> termLevels = [
    {'label': 'الفصل الأول', 'value': '1'},
    {'label': 'الفصل الثاني', 'value': '2'},
  ];
  String? selectedTermLabel;

  bool _isFinalSecondary = false;
  DateTime? selectedBirthDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال هذا الحقل';
    return null;
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    if (selectedGenderLabel == null ||
        selectedMadhabLabel == null ||
        selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    final genderValue = genders
        .firstWhere((g) => g['label'] == selectedGenderLabel)['value'];
    final branchValue = selectedBranchLabel == null
        ? null
        : branches.firstWhere((b) => b['label'] == selectedBranchLabel)['value'];
    final madhabValue = madhabs
        .firstWhere((m) => m['label'] == selectedMadhabLabel)['value'];
    final termValue = selectedTermLabel == null
        ? null
        : termLevels.firstWhere((t) => t['label'] == selectedTermLabel)['value'];

    final updatedData = widget.registrationData.copyWith(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      gender: genderValue,
      birthDate: selectedBirthDate!.toIso8601String().split('T')[0],
      isFinalSecondary: _isFinalSecondary,
      schoolBranch: branchValue,
      madhab: madhabValue,
      termLevel: termValue,
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterStep5View(registrationData: updatedData),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFlowPopScope(
      isBusy: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.gray50,
          appBar: ProfileFlowAppBar(
            title: 'استكمال البيانات',
            isBusy: false,
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
                    Row(
                      children: List.generate(5, (index) {
                        final bool isCompleted = index < 4;
                        final bool isCurrent = index == 3;
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
                            'أخبرنا المزيد عن نفسك',
                            style: TextStyle(
                              color: AppColors.gray600,
                              fontSize: 16,
                            ),
                          ),
                          Gap(24),
                          BuildField(
                            title: 'الاسم الأول',
                            child: CustomTextField(
                              hint: 'ادخل اسمك الأول',
                              isPassword: false,
                              controller: firstNameController,
                              validator: _validateRequired,
                            ),
                          ),
                          Gap(16),
                          BuildField(
                            title: 'الاسم الأخير',
                            child: CustomTextField(
                              hint: 'ادخل اسمك الأخير',
                              isPassword: false,
                              controller: lastNameController,
                              validator: _validateRequired,
                            ),
                          ),
                          Gap(16),
                          BuildField(
                            title: 'الجنس',
                            child: CustomDropdown<String>(
                              hint: 'اختر الجنس',
                              items: genders.map((g) => g['label']!).toList(),
                              itemAsString: (item) => item,
                              value: selectedGenderLabel,
                              onChanged: (value) =>
                                  setState(() => selectedGenderLabel = value),
                              required: true,
                            ),
                          ),
                          Gap(16),
                          BuildField(
                            title: 'تاريخ الميلاد',
                            child: CustomDateField(
                              hint: 'تاريخ الميلاد',
                              selectedDate: selectedBirthDate,
                              onChanged: (date) =>
                                  setState(() => selectedBirthDate = date),
                              required: true,
                            ),
                          ),
                          Gap(16),
                          BuildField(
                            title: 'المذهب',
                            child: CustomDropdown<String>(
                              hint: 'اختر المذهب',
                              items: madhabs.map((m) => m['label']!).toList(),
                              itemAsString: (item) => item,
                              value: selectedMadhabLabel,
                              onChanged: (value) =>
                                  setState(() => selectedMadhabLabel = value),
                              required: true,
                            ),
                          ),
                          Gap(16),
                          BuildField(
                            title: 'الشعبة (اختياري)',
                            child: CustomDropdown<String>(
                              hint: 'اختر الشعبة',
                              items: branches.map((b) => b['label']!).toList(),
                              itemAsString: (item) => item,
                              value: selectedBranchLabel,
                              onChanged: (value) =>
                                  setState(() => selectedBranchLabel = value),
                            ),
                          ),
                          Gap(16),
                          BuildField(
                            title: 'الفصل الدراسي (اختياري)',
                            child: CustomDropdown<String>(
                              hint: 'اختر الفصل الدراسي',
                              items: termLevels.map((t) => t['label']!).toList(),
                              itemAsString: (item) => item,
                              value: selectedTermLabel,
                              onChanged: (value) =>
                                  setState(() => selectedTermLabel = value),
                            ),
                          ),
                          Gap(8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.brandPrimary,
                            title: CustomText(
                              text: 'أنا في السنة الأخيرة من الثانوية',
                              color: AppColors.gray900,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                            value: _isFinalSecondary,
                            onChanged: (value) =>
                                setState(() => _isFinalSecondary = value),
                          ),
                          Gap(24),
                          CustomElevatedButton(
                            text: 'المتابعة',
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: _next,
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
}
