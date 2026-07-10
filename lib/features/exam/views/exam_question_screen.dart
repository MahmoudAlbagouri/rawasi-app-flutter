// lib/features/exam/views/exam_question_screen.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/exam/data/question_item.dart';
import 'package:rawasi_app_n/features/exam/views/exam_answer_screen.dart';

class ExamQuestionScreen extends StatefulWidget {
  final List<QuestionItem> questions;
  final int currentQuestionIndex;
  final List<String> selectedAnswers;
  final int dayId;

  const ExamQuestionScreen({
    super.key,
    required this.questions,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.dayId,
  });

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  bool _isCurrentAnswered() {
    final answer = widget.selectedAnswers[widget.currentQuestionIndex];
    return answer != null && answer.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[widget.currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('السؤال'),
        centerTitle: true,
        actions: [
          if (widget.currentQuestionIndex < widget.questions.length - 1)
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                color: _isCurrentAnswered() ? Colors.black : AppColors.gray400,
              ),
              onPressed: _isCurrentAnswered()
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamQuestionScreen(
                            questions: widget.questions,
                            currentQuestionIndex:
                                widget.currentQuestionIndex + 1,
                            selectedAnswers: widget.selectedAnswers,
                            dayId: widget.dayId,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // شريط التقدم (قابل للنقر على الأسئلة المجابة فقط)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.questions.length, (index) {
                  final isCurrent = index == widget.currentQuestionIndex;
                  final isAnswered = widget.selectedAnswers[index].isNotEmpty;

                  Widget dot = Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? AppColors.brandPrimary
                          : isCurrent
                          ? AppColors.primary300
                          : AppColors.primary100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );

                  if (isAnswered && index != widget.currentQuestionIndex) {
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExamQuestionScreen(
                                questions: widget.questions,
                                currentQuestionIndex: index,
                                selectedAnswers: widget.selectedAnswers,
                                dayId: widget.dayId,
                              ),
                            ),
                          );
                        },
                        child: dot,
                      ),
                    );
                  } else {
                    return Expanded(child: dot);
                  }
                }),
              ),
              const SizedBox(height: 24),

              // نوع السؤال (إن وُجد)
              if (currentQuestion.questionType != null &&
                  currentQuestion.questionType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.brandPrimary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    currentQuestion.questionType!,
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (currentQuestion.questionType != null &&
                  currentQuestion.questionType!.isNotEmpty)
                const SizedBox(height: 20),

              // رقم السؤال
              Text(
                'السؤال ${widget.currentQuestionIndex + 1}',
                style: TextStyle(
                  color: AppColors.brandSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // نص السؤال
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    currentQuestion.question,
                    style: TextStyle(
                      color: AppColors.gray800,
                      fontSize: 16,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // زر إظهار الإجابة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamAnswerScreen(
                          questionIndex: widget.currentQuestionIndex,
                          questions: widget.questions,
                          selectedAnswers: widget.selectedAnswers,
                          dayId: widget.dayId,
                        ),
                      ),
                    );

                    if (result is List<String>) {
                      setState(() {
                        for (int i = 0; i < result.length; i++) {
                          widget.selectedAnswers[i] = result[i];
                        }
                      });

                      if (widget.currentQuestionIndex <
                          widget.questions.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamQuestionScreen(
                              questions: widget.questions,
                              currentQuestionIndex:
                                  widget.currentQuestionIndex + 1,
                              selectedAnswers: widget.selectedAnswers,
                              dayId: widget.dayId,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'إظهار الإجابة',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
