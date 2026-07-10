// lib/features/home/widgets/quran_level_indicator.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

List<String> _levelLabels = ['ضعيف', 'متوسط', 'جيد', 'جيد جدًا', 'ممتاز'];

class QuranLevelIndicator extends StatelessWidget {
  final int currentLevel; // من 1 إلى 5 (0 = غير محدد)

  const QuranLevelIndicator({super.key, required this.currentLevel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'مستوى القرآن',
            color: AppColors.brandSecondary,
            size: 16,
            weight: FontWeight.bold,
          ),
          const SizedBox(height: 16),
          // عرض المستويات كنصوص أفقية
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _levelLabels.length,
              itemBuilder: (context, index) {
                final levelNumber = index + 1;
                final isCurrent = levelNumber == currentLevel;
                final label = _levelLabels[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isCurrent
                          ? AppColors.brandPrimary
                          : AppColors.gray100,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.white
                              : AppColors.gray800,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          CustomText(
            text: 'كل مستوى يمثل تقدمًا في حفظ القرآن الكريم',
            color: AppColors.gray600,
            size: 12,
          ),
        ],
      ),
    );
  }
}
