// lib/features/quran_test/quran_test_screen.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/quran_test/quran_self_assessment_data.dart';
import 'package:rawasi_app_n/features/quran_test/quran_test_question.dart';
import 'package:rawasi_app_n/features/quran_test/quran_test_result_screen.dart';

class QuranTestScreen extends StatefulWidget {
  const QuranTestScreen({super.key});

  @override
  State<QuranTestScreen> createState() => _QuranTestScreenState();
}

class _QuranTestScreenState extends State<QuranTestScreen> {
  int currentQuestionIndex = 0;
  List<bool?> answers = List.filled(quranSelfAssessmentItems.length, null);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: currentQuestionIndex > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      currentQuestionIndex--;
                    });
                  },
                )
              : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(quranSelfAssessmentItems.length, (
                    index,
                  ) {
                    final isAnswered = answers[index] != null;
                    final isSelected = index == currentQuestionIndex;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? AppColors.brandPrimary
                              : isSelected
                              ? AppColors.primary300
                              : AppColors.primary100,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                QuranTestQuestion(
                  stem: quranSelfAssessmentItems[currentQuestionIndex].stem,
                  currentAnswer: answers[currentQuestionIndex],
                  onAnswerSelect: (bool? answer) {
                    setState(() {
                      answers[currentQuestionIndex] = answer;
                    });
                  },
                  onContinue: () {
                    if (currentQuestionIndex <
                        quranSelfAssessmentItems.length - 1) {
                      setState(() {
                        currentQuestionIndex++;
                      });
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuranTestResultScreen(answers: answers),
                        ),
                      );
                    }
                  },
                  canContinue: answers[currentQuestionIndex] != null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
