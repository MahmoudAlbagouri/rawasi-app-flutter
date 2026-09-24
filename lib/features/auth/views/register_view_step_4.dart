// lib/features/auth/views/register_view_step_4.dart
//
// Complete-profile part A: name, gender, birth date, madhab and school branch.
// Carried forward to part B in the shared draft before the API call.
//
// free first month: the term ("الفصل الدراسي") picker and the "أنا في السنة
// الأخيرة من الثانوية" switch are gone - the backend no longer accepts either,
// and course visibility no longer depends on term. المذهب offers Hanafi and
// Shafii only, and الشعبة is now required.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_5.dart';
import 'package:rawasi_app_n/features/auth/widgets/build_field.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';
import 'package:rawasi_app_n/shared/custom_date_field.dart';
import 'package:rawasi_app_n/shared/custom_dropdown.dart';
import 'package:rawasi_app_n/shared/custom_text_field.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

/// The latest date that can be a birth date.
///
/// The API validates `before:today`, so *today itself* is invalid. Capping the
/// picker at today (the old behaviour) let the student choose a date the server
/// then rejected on the final submit, several screens later - which is exactly
/// the late error this replaces.
DateTime latestBirthDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
}

class RegisterStep4View extends StatefulWidget {
  final RegistrationDraft draft;
  const RegisterStep4View({super.key, required this.draft});

  @override
  State<RegisterStep4View> createState() => _RegisterStep4ViewState();
}

class _RegisterStep4ViewState extends State<RegisterStep4View> {
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;

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

  // free first month: the student-facing picker is limited to these two. The
  // backend's Madhab enum still holds Maliki and Hanbali for existing data, but
  // CompleteProfileRequest only accepts what is offered here.
  final List<Map<String, String>> madhabs = [
    {'label': 'حنفي', 'value': 'hanafi'},
    {'label': 'شافعي', 'value': 'shafii'},
  ];
  String? selectedMadhabLabel;

  DateTime? selectedBirthDate;
  String? _birthDateError;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Seed from the draft: coming back to this step must show what was already
    // entered, whether the student arrived here forwards or backwards.
    final d = widget.draft.data;
    firstNameController = TextEditingController(text: d.firstName);
    lastNameController = TextEditingController(text: d.lastName);
    selectedGenderLabel = _labelFor(genders, d.gender);
    selectedBranchLabel = _labelFor(branches, d.schoolBranch);
    selectedMadhabLabel = _labelFor(madhabs, d.madhab);
    selectedBirthDate = DateTime.tryParse(d.birthDate);
  }

  static String? _labelFor(List<Map<String, String>> options, String? value) {
    if (value == null || value.isEmpty) return null;
    for (final o in options) {
      if (o['value'] == value) return o['label'];
    }
    return null;
  }

  static String? _valueFor(List<Map<String, String>> options, String? label) {
    if (label == null) return null;
    for (final o in options) {
      if (o['label'] == label) return o['value'];
    }
    return null;
  }

  /// Write this step's values into the shared draft.
  ///
  /// Called both on the way forward and from dispose(), so leaving by the back
  /// arrow or the system gesture preserves the form just as well as pressing
  /// "المتابعة" does.
  void _saveToDraft() {
    widget.draft.save((current) => current.copyWith(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          gender: _valueFor(genders, selectedGenderLabel) ?? '',
          birthDate: selectedBirthDate == null
              ? ''
              : selectedBirthDate!.toIso8601String().split('T')[0],
          schoolBranch: _valueFor(branches, selectedBranchLabel),
          madhab: _valueFor(madhabs, selectedMadhabLabel) ?? '',
        ));
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال هذا الحقل';
    return null;
  }

  /// Inline, at the moment of selection - not after the final submit.
  void _onBirthDateChanged(DateTime? date) {
    setState(() {
      selectedBirthDate = date;
      _birthDateError = date == null
          ? 'الرجاء اختيار تاريخ الميلاد'
          : (date.isAfter(latestBirthDate())
              ? 'يجب أن يكون تاريخ الميلاد قبل اليوم'
              : null);
    });
  }

  void _next() {
    final formOk = _formKey.currentState!.validate();

    if (selectedBirthDate == null) {
      setState(() => _birthDateError = 'الرجاء اختيار تاريخ الميلاد');
    }

    if (!formOk ||
        selectedBirthDate == null ||
        _birthDateError != null ||
        selectedGenderLabel == null ||
        selectedMadhabLabel == null ||
        selectedBranchLabel == null) {
      return;
    }

    _saveToDraft();

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterStep5View(draft: widget.draft),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    // The catch-all that makes back-navigation lossless, whichever way the
    // student left. Controllers are still readable here.
    _saveToDraft();
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
          appBar: const ProfileFlowAppBar(title: 'استكمال البيانات'),
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _progress(),
                    const Gap(24),
                    Expanded(
                      child: ListView(
                        children: [
                          const Text(
                            'أخبرنا المزيد عن نفسك',
                            style: TextStyle(
                              color: AppColors.gray600,
                              fontSize: 16,
                            ),
                          ),
                          const Gap(24),
                          BuildField(
                            title: 'الاسم الأول',
                            child: CustomTextField(
                              hint: 'ادخل اسمك الأول',
                              isPassword: false,
                              controller: firstNameController,
                              validator: _validateRequired,
                            ),
                          ),
                          const Gap(16),
                          BuildField(
                            title: 'الاسم الأخير',
                            child: CustomTextField(
                              hint: 'ادخل اسمك الأخير',
                              isPassword: false,
                              controller: lastNameController,
                              validator: _validateRequired,
                            ),
                          ),
                          const Gap(16),
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
                          const Gap(16),
                          BuildField(
                            title: 'تاريخ الميلاد',
                            child: CustomDateField(
                              hint: 'تاريخ الميلاد',
                              selectedDate: selectedBirthDate,
                              lastDate: latestBirthDate(),
                              errorText: _birthDateError,
                              onChanged: _onBirthDateChanged,
                              required: true,
                            ),
                          ),
                          const Gap(16),
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
                          const Gap(16),
                          BuildField(
                            // Required now: it decides whether the student is
                            // shown the علمي or the أدبي stream.
                            title: 'الشعبة',
                            child: CustomDropdown<String>(
                              hint: 'اختر الشعبة',
                              items: branches.map((b) => b['label']!).toList(),
                              itemAsString: (item) => item,
                              value: selectedBranchLabel,
                              onChanged: (value) =>
                                  setState(() => selectedBranchLabel = value),
                              required: true,
                            ),
                          ),
                          const Gap(24),
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

  Widget _progress() {
    return Row(
      children: List.generate(5, (index) {
        final isCompleted = index < 4;
        final isCurrent = index == 3;
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
