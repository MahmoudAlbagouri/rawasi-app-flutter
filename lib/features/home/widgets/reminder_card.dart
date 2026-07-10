// lib/features/home/widgets/reminder_card.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class ReminderCard extends StatelessWidget {
  final List<bool> days;

  const ReminderCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final dayNames = [
      'سبت',
      'أحد',
      'اثنين',
      'ثلاثاء',
      'أربعاء',
      'خميس',
      'جمعة',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary800,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary900.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'تذكير بالورد اليومي',
                      color: AppColors.white,
                      size: 16,
                      weight: FontWeight.bold,
                    ),
                    Gap(4),
                    CustomText(
                      text: 'استمر في التلاوة اليومية',
                      color: AppColors.gray200,
                      size: 13,
                    ),
                  ],
                ),
              ),
              Gap(12),
              Image.asset('assets/images/quran.jfif', width: 52, height: 52),
            ],
          ),
          Gap(16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dayNames.length,
              itemBuilder: (context, index) {
                final isCompleted = index < days.length ? days[index] : false;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 52,
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.success600
                                : AppColors.gray300,
                          ),
                          child: isCompleted
                              ? Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                        Gap(4),
                        CustomText(
                          text: dayNames[index],
                          color: AppColors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
