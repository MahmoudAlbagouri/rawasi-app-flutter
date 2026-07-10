// lib/features/quran_test/quran_test_question.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

class QuranTestQuestion extends StatelessWidget {
  final String stem;
  final bool? currentAnswer;
  final void Function(bool?) onAnswerSelect;
  final void Function() onContinue;
  final bool canContinue;

  const QuranTestQuestion({
    super.key,
    required this.stem,
    required this.currentAnswer,
    required this.onAnswerSelect,
    required this.onContinue,
    required this.canContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'اكمل الآية مع ذكر آية بعدها',
          style: TextStyle(
            color: AppColors.brandSecondary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stem,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.gray800,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '...',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.gray500, fontSize: 16),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => onAnswerSelect(true),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentAnswer == true
                  ? AppColors.primary50
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سمعتها الحمد لله',
                  style: TextStyle(
                    color: currentAnswer == true
                        ? AppColors.brandSuccess
                        : AppColors.gray800,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  currentAnswer == true
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: currentAnswer == true
                      ? AppColors.brandSuccess
                      : AppColors.gray400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => onAnswerSelect(false),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentAnswer == false
                  ? AppColors.primary50
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'لسّه محتاج أراجعها',
                  style: TextStyle(
                    color: currentAnswer == false
                        ? AppColors.brandError
                        : AppColors.gray800,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  currentAnswer == false
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: currentAnswer == false
                      ? AppColors.brandError
                      : AppColors.gray400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canContinue ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canContinue
                  ? AppColors.brandPrimary
                  : AppColors.gray300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'استمرار',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
