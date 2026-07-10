// lib/features/exam/views/exam_loading_screen.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/exam/data/exam_repo.dart';
import 'package:rawasi_app_n/features/exam/data/question_item.dart';
import 'package:rawasi_app_n/features/exam/views/exam_question_screen.dart';

class ExamLoadingScreen extends StatefulWidget {
  final int dayId;
  final int courseId;

  const ExamLoadingScreen({
    super.key,
    required this.dayId,
    required this.courseId,
  });

  @override
  State<ExamLoadingScreen> createState() => _ExamLoadingScreenState();
}

class _ExamLoadingScreenState extends State<ExamLoadingScreen> {
  late Future<List<QuestionItem>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = ExamRepo().fetchQuestions(widget.courseId, widget.dayId);
  }

  String _markAsToLabel(String? markAs) {
    switch (markAs?.toLowerCase()) {
      case 'easy':
        return 'سهل';
      case 'hard':
        return 'صعب';
      case 'good':
        return 'جيد';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FutureBuilder<List<QuestionItem>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: AppColors.error500),
                  const SizedBox(height: 16),
                  Text(
                    'فشل تحميل الأسئلة: ${snapshot.error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.gray700),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _questionsFuture = ExamRepo().fetchQuestions(
                          widget.courseId,
                          widget.dayId,
                        );
                      });
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final questions = snapshot.data ?? [];
          if (questions.isEmpty) {
            return Center(
              child: Text(
                'لا توجد أسئلة لهذا اليوم',
                style: TextStyle(color: AppColors.gray700),
              ),
            );
          }

          final initialSelectedAnswers = questions.map((question) {
            return _markAsToLabel(question.markAs);
          }).toList();

          // 🔑 البحث عن أول سؤال غير مجاب
          int firstUnansweredIndex = 0;
          for (int i = 0; i < questions.length; i++) {
            if (initialSelectedAnswers[i].isEmpty) {
              firstUnansweredIndex = i;
              break;
            }
          }

          return ExamQuestionScreen(
            questions: questions,
            currentQuestionIndex: firstUnansweredIndex,
            selectedAnswers: initialSelectedAnswers,
            dayId: widget.dayId,
          );
        },
      ),
    );
  }
}
