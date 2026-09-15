// lib/features/auth/views/register_view_step_1.dart
//
// Step 1: choose academic grade, then a subscription plan for that grade.
// Registration itself requires both (`academic_year` + `plan_id`).

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_repo.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_2.dart';
import 'package:rawasi_app_n/features/auth/widgets/card_subscription.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

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
  Future<List<SubscriptionPlan>>? _plansFuture;

  void _selectGrade(String grade) {
    setState(() {
      _selectedGrade = grade;
      _plansFuture = SubscriptionRepo().fetchPlans(grade: grade);
    });
  }

  void _choosePlan(SubscriptionPlan plan) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterStep2View(
              initialData: RegistrationData(
                academicYear: _selectedGrade!,
                planId: plan.id,
              ),
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              Gap(24),
              CustomText(
                text: 'ما هو صفك الدراسي؟',
                color: AppColors.gray900,
                size: 18,
                weight: FontWeight.bold,
              ),
              Gap(16),
              Row(
                children: _grades.map((g) {
                  final selected = _selectedGrade == g['value'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _selectGrade(g['value']!),
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
                              color: selected ? Colors.white : AppColors.gray800,
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
              Gap(24),
              if (_selectedGrade != null) ...[
                CustomText(
                  text: 'اختر باقة الاشتراك',
                  color: AppColors.gray900,
                  size: 18,
                  weight: FontWeight.bold,
                ),
                Gap(16),
                Expanded(
                  child: FutureBuilder<List<SubscriptionPlan>>(
                    future: _plansFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: CustomText(
                            text: 'فشل تحميل الباقات',
                            color: AppColors.error600,
                            size: 15,
                          ),
                        );
                      }
                      final plans = snapshot.data ?? [];
                      if (plans.isEmpty) {
                        return Center(
                          child: CustomText(
                            text: 'لا توجد باقات متاحة لهذا الصف',
                            color: AppColors.gray600,
                            size: 15,
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: plans.length,
                        separatorBuilder: (context, index) => const Gap(16),
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return SubscriptionCard(
                            plan: plan,
                            onPressed: () => _choosePlan(plan),
                          );
                        },
                      );
                    },
                  ),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: CustomText(
                      text: 'اختر صفك الدراسي لعرض الباقات المتاحة',
                      color: AppColors.gray600,
                      size: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(5, (index) {
        final bool isCompleted = index < 1;
        final bool isCurrent = index == 0;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted || isCurrent
                  ? AppColors.brandPrimary
                  : AppColors.primary100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
