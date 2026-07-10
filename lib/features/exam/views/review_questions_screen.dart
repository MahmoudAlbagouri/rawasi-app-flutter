// lib/features/exam/views/review_questions_screen.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/exam/data/mark_as_repo.dart';
import 'package:rawasi_app_n/features/exam/data/question_item.dart';
import 'package:rawasi_app_n/features/exam/views/exam_result_screen.dart';

class ReviewQuestionsScreen extends StatefulWidget {
  final List<ReviewQuestionItem> reviewQuestions;
  final List<String> selectedAnswers;
  final int dayId;
  final Function(List<String>) onCompleted;

  const ReviewQuestionsScreen({
    super.key,
    required this.reviewQuestions,
    required this.selectedAnswers,
    required this.dayId,
    required this.onCompleted,
  });

  @override
  State<ReviewQuestionsScreen> createState() => _ReviewQuestionsScreenState();
}

class _ReviewQuestionsScreenState extends State<ReviewQuestionsScreen> {
  late List<ReviewQuestionItem> _questions;
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.reviewQuestions);
  }

  Future<void> _markAsEasy() async {
    if (_isProcessing || _questions.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final current = _questions[_currentIndex];
      final markRepo = MarkAsRepo();

      // تحديث العلامة على السيرفر
      await markRepo.markAs(
        current.questionItem.dailyTaskId,
        'easy',
        widget.dayId,
      );

      // التحرك إلى السؤال التالي
      final nextIndex = _currentIndex + 1;

      if (nextIndex < _questions.length) {
        setState(() {
          _currentIndex = nextIndex;
        });
      } else {
        _completeReview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحديث: ${e.toString()}'),
            backgroundColor: AppColors.error600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _completeReview() {
    final updatedAnswers = List<String>.from(widget.selectedAnswers);

    // تحديث جميع الأسئلة التي تمت مراجعتها إلى "سهل"
    for (int i = 0; i <= _currentIndex; i++) {
      final q = _questions[i];
      updatedAnswers[q.index] = 'سهل';
    }

    widget.onCompleted(updatedAnswers);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.brandPrimary),
              const SizedBox(height: 16),
              Text(
                'جاري إكمال المراجعة...',
                style: TextStyle(fontSize: 16, color: AppColors.gray700),
              ),
            ],
          ),
        ),
      );
    }

    final current = _questions[_currentIndex];

    // === الحل الجذري: استخدام LayoutBuilder لضمان قيود تخطيط صحيحة ===
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: Text(
              'مراجعة السؤال ${_currentIndex + 1} من ${_questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              primary: false, // ← منع التعارض مع الـ AppBar
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  // ← ضمان ارتفاع داخلي صحيح
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // نوع السؤال
                        if (current.questionItem.questionType != null &&
                            current.questionItem.questionType!.isNotEmpty)
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
                              current.questionItem.questionType!,
                              style: TextStyle(
                                color: AppColors.brandPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (current.questionItem.questionType != null &&
                            current.questionItem.questionType!.isNotEmpty)
                          const SizedBox(height: 20),

                        // تصنيف السؤال الحالي
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: current.currentMark == 'صعب'
                                ? AppColors.error50
                                : AppColors.primary50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                current.currentMark == 'صعب'
                                    ? Icons.priority_high
                                    : Icons.grade,
                                color: current.currentMark == 'صعب'
                                    ? AppColors.error700
                                    : AppColors.brandPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'هذا السؤال مصنف كـ "${current.currentMark}"',
                                style: TextStyle(
                                  color: current.currentMark == 'صعب'
                                      ? AppColors.error800
                                      : AppColors.brandSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // === السؤال ===
                        Text(
                          'السؤال:',
                          style: TextStyle(
                            color: AppColors.brandSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            current.questionItem.question,
                            style: TextStyle(
                              color: AppColors.gray800,
                              fontSize: 16,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // === الإجابة ===
                        Text(
                          'الإجابة:',
                          style: TextStyle(
                            color: AppColors.brandSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brandPrimary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            current.questionItem.answer ?? 'لا يوجد إجابة',
                            style: TextStyle(
                              color: AppColors.gray800,
                              fontSize: 16,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // زر التحويل إلى سهل (بدون أي عناصر متحركة)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _markAsEasy,
                            // ← استبدال الـ CircularProgressIndicator بأيقونة ثابتة
                            icon: _isProcessing
                                ? const Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              _isProcessing
                                  ? 'جاري التحديث...'
                                  : 'تحويل هذا السؤال إلى "سهل"',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isProcessing
                                  ? AppColors.gray400
                                  : AppColors.brandPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // === شريط التقدم كنقاط (بدون أي حركات) ===
                        if (_questions.length > 1)
                          SizedBox(
                            height: 60,
                            child: Column(
                              children: [
                                Text(
                                  'الأسئلة: ${_currentIndex + 1} / ${_questions.length}',
                                  style: TextStyle(
                                    color: AppColors.gray700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_questions.length, (
                                    index,
                                  ) {
                                    final isCurrent = index == _currentIndex;
                                    final isCompleted = index < _currentIndex;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: Container(
                                        width: isCurrent ? 14 : 10,
                                        height: isCurrent ? 14 : 10,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppColors.brandPrimary
                                              : isCurrent
                                              ? AppColors.brandPrimary
                                              : AppColors.gray300,
                                          shape: BoxShape.circle,
                                          border: isCurrent
                                              ? Border.all(
                                                  color: AppColors.brandPrimary
                                                      .withOpacity(0.3),
                                                  width: 3,
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  }),
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
      },
    );
  }
}
