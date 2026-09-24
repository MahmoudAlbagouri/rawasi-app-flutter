// lib/features/auth/views/register_view_step_1.dart
//
// Step 1: choose the academic grade.
//
// free first month: the subscription-plan picker is gone. Registration no
// longer sends plan_id at all - it is nullable server-side, and check-otp puts
// every new student on the seeded "الشهر المجاني" plan. The plan screens
// (SubscriptionCard / SubscriptionRepo) are left in the codebase untouched for
// when paid plans come back.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_2.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:rawasi_app_n/shared/main_button.dart';

class RegisterStep1View extends StatefulWidget {
  const RegisterStep1View({super.key});

  @override
  State<RegisterStep1View> createState() => _RegisterStep1ViewState();
}

class _RegisterStep1ViewState extends State<RegisterStep1View> {
  final List<Map<String, String>> _grades = [
    {'label': 'الصف الأول الثانوي', 'value': '1'},
    {'label': 'الصف الثاني الثانوي', 'value': '2'},
    {'label': 'الصف الثالث الثانوي', 'value': '3'},
  ];

  String? _selectedGrade;

  void _continue() {
    if (_selectedGrade == null) return;

    // One draft, created here and carried through every later step. This is
    // what makes going back and forth lossless.
    final draft = RegistrationDraft(
      RegistrationData(academicYear: _selectedGrade!),
    );

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterStep2View(draft: draft),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
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
        scrolledUnderElevation: 0,
        title: const CustomText(
          text: 'إنشاء الحساب',
          color: AppColors.brandPrimary,
          size: 18,
          weight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const Gap(24),
              const CustomText(
                text: 'ما هو صفك الدراسي؟',
                color: AppColors.gray900,
                size: 18,
                weight: FontWeight.bold,
              ),
              const Gap(16),
              Row(
                children: _grades.map((g) {
                  final selected = _selectedGrade == g['value'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedGrade = g['value']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.brandPrimary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.brandPrimary
                                  : AppColors.gray300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            g['label']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.gray800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Gap(24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.card_giftcard_outlined,
                      color: AppColors.brandPrimary,
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          CustomText(
                            text: 'الشهر الأول مجانًا',
                            color: AppColors.brandPrimary,
                            size: 15,
                            weight: FontWeight.bold,
                          ),
                          Gap(4),
                          CustomText(
                            text:
                                'لا حاجة لاختيار باقة أو دفع أي رسوم للاشتراك الآن.',
                            color: AppColors.gray700,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CustomElevatedButton(
                text: 'المتابعة',
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _selectedGrade == null ? null : _continue,
              ),
              const Gap(12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(5, (index) {
        final bool isCurrent = index == 0;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.brandPrimary : AppColors.primary100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
