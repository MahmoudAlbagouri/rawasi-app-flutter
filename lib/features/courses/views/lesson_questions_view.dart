// lib/features/courses/views/lesson_questions_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/courses/data/courses_repo.dart';
import 'package:rawasi_app_n/features/courses/data/question.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class LessonQuestionsView extends StatefulWidget {
  final int lessonId;
  final int courseId;
  final String lessonTitle;

  const LessonQuestionsView({
    super.key,
    required this.lessonId,
    required this.courseId,
    required this.lessonTitle,
  });

  @override
  State<LessonQuestionsView> createState() => _LessonQuestionsViewState();
}

class _LessonQuestionsViewState extends State<LessonQuestionsView> {
  final CoursesRepo _repo = CoursesRepo();
  late Future<List<Question>> _questionsFuture;
  final Set<int> _revealed = {};
  bool _isFinishingLesson = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _repo.fetchQuestions(widget.lessonId);
  }

  Future<void> _completeQuestion(Question question) async {
    try {
      final result = await _repo.completeQuestion(question.questionId);
      if (!mounted) return;
      setState(() {
        _questionsFuture = _repo.fetchQuestions(widget.lessonId);
      });
      if (result['lesson_completed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أحسنت! أنهيت هذا الدرس بالكامل 🎉')),
        );
      }
    } catch (e) {
      final msg = e is ApiError ? e.message : 'فشل تحديد السؤال كمكتمل';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error600),
        );
      }
    }
  }

  Future<void> _finishWholeLesson() async {
    setState(() => _isFinishingLesson = true);
    try {
      await _repo.completeLesson(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _questionsFuture = _repo.fetchQuestions(widget.lessonId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنهاء الدرس بنجاح')),
      );
    } catch (e) {
      final msg = e is ApiError ? e.message : 'فشل إنهاء الدرس';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error600),
        );
      }
    } finally {
      if (mounted) setState(() => _isFinishingLesson = false);
    }
  }

  Future<void> _addToLibrary(Question question) async {
    try {
      await LibraryRepo().addToLibrary(
        courseId: widget.courseId,
        questionId: question.questionId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الإضافة إلى المكتبة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final msg = snapshot.error is ApiError
                  ? (snapshot.error as ApiError).message
                  : 'فشل تحميل الأسئلة';
              return Center(
                child: CustomText(text: msg, color: AppColors.error600, size: 15),
              );
            }
            final questions = snapshot.data ?? [];
            if (questions.isEmpty) {
              return Center(
                child: CustomText(
                  text: 'لا توجد أسئلة في هذا الدرس',
                  color: AppColors.gray600,
                  size: 15,
                ),
              );
            }

            final allCompleted = questions.every((q) => q.isCompleted);

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) =>
                        _questionCard(questions[index]),
                  ),
                ),
                if (!allCompleted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFinishingLesson ? null : _finishWholeLesson,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _isFinishingLesson
                              ? 'جاري الإنهاء...'
                              : 'أنهيت هذا الدرس',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _questionCard(Question question) {
    final revealed = _revealed.contains(question.questionId) || question.isCompleted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: question.isCompleted
              ? AppColors.success500.withOpacity(0.4)
              : AppColors.gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                question.isCompleted ? Icons.check_circle : Icons.quiz_outlined,
                color: question.isCompleted
                    ? AppColors.success600
                    : AppColors.brandPrimary,
                size: 22,
              ),
              const Gap(8),
              Expanded(
                child: CustomText(
                  text: question.question,
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                color: AppColors.gray500,
                onPressed: () => _addToLibrary(question),
                tooltip: 'إضافة إلى المكتبة',
              ),
            ],
          ),
          const Gap(10),
          if (revealed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomText(
                text: question.answer,
                color: AppColors.gray700,
                size: 14,
              ),
            )
          else
            TextButton(
              onPressed: () => setState(() => _revealed.add(question.questionId)),
              child: const Text('إظهار الإجابة'),
            ),
          if (!question.isCompleted) ...[
            const Gap(10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _completeQuestion(question),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.brandPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'تحديد كمكتمل',
                  style: TextStyle(color: AppColors.brandPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
