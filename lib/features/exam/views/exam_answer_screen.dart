// lib/features/exam/views/exam_answer_screen.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/repositories/library_repository.dart';
import 'package:rawasi_app_n/features/exam/data/mark_as_repo.dart';
import 'package:rawasi_app_n/features/exam/data/question_item.dart';
import 'package:rawasi_app_n/features/exam/views/exam_result_screen.dart';

class ExamAnswerScreen extends StatefulWidget {
  final int questionIndex;
  final List<QuestionItem> questions;
  final List<String> selectedAnswers;
  final int dayId;

  const ExamAnswerScreen({
    super.key,
    required this.questionIndex,
    required this.questions,
    required this.selectedAnswers,
    required this.dayId,
  });

  @override
  State<ExamAnswerScreen> createState() => _ExamAnswerScreenState();
}

class _ExamAnswerScreenState extends State<ExamAnswerScreen> {
  bool _isAddedToLibrary = false;
  bool _isAdding = false;

  String _getMarkAsLabel(String? markAs) {
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

  void _addToLibrary() async {
    if (_isAddedToLibrary || _isAdding) return;

    final current = widget.questions[widget.questionIndex];
    setState(() {
      _isAdding = true;
    });

    try {
      final repo = LibraryRepository();
      await repo.addToLibrary(
        type: 'question',
        taskId: current.questionId,
        courseId: current.courseId,
      );

      if (mounted) {
        setState(() {
          _isAddedToLibrary = true;
          _isAdding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت الإضافة إلى المكتبة بنجاح'),
            backgroundColor: AppColors.success600,
          ),
        );
      }
    } on Exception catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.toLowerCase().contains('تمت اضافتها من قبل')) {
        if (mounted) {
          setState(() {
            _isAddedToLibrary = true;
            _isAdding = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تمت الإضافة إلى المكتبة مسبقًا'),
              backgroundColor: AppColors.brandPrimary,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isAdding = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل الإضافة: $errorMsg'),
              backgroundColor: AppColors.error600,
            ),
          );
        }
      }
    }
  }

  void _submitRatingAndNavigate(String ratingLabel) async {
    String markValue;
    switch (ratingLabel) {
      case 'سهل':
        markValue = 'easy';
        break;
      case 'جيد':
        markValue = 'good';
        break;
      case 'صعب':
        markValue = 'hard';
        break;
      default:
        markValue = 'good';
    }

    final current = widget.questions[widget.questionIndex];
    final dailyTaskId = current.dailyTaskId;
    try {
      final markRepo = MarkAsRepo();
      await markRepo.markAs(dailyTaskId, markValue, widget.dayId);

      final updatedAnswers = List<String>.from(widget.selectedAnswers);
      updatedAnswers[widget.questionIndex] = ratingLabel;

      final isLast = widget.questionIndex == widget.questions.length - 1;
      if (isLast) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(
              selectedAnswers: updatedAnswers,
              questions: widget.questions, // ← إضافة الأسئلة
              dayId: widget.dayId, // ← إضافة dayId
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pop(context, updatedAnswers);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ التقييم: $e'),
          backgroundColor: AppColors.error600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[widget.questionIndex];
    final savedMarkAsLabel = _getMarkAsLabel(currentQuestion.markAs);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('الإجابة'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 نوع السؤال (جديد - نفس التصميم)
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
                  child: Align(
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
                ),
              Gap(15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  child: Text(
                    currentQuestion.question,
                    style: TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (currentQuestion.questionType != null &&
                  currentQuestion.questionType!.isNotEmpty)
                const SizedBox(height: 20),

              Text(
                'الإجابة:',
                style: TextStyle(
                  color: AppColors.brandSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // مربع الإجابة (يدعم النصوص الطويلة)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      currentQuestion.answer ?? 'لا يوجد إجابة',
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
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'ما رأيك في هذا السؤال؟',
                style: TextStyle(
                  color: AppColors.gray900,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // خيارات التقييم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRatingOption(
                    label: 'صعب',
                    bgColor: AppColors.error50,
                    textColor: AppColors.error700,
                    isSelected: savedMarkAsLabel == 'صعب',
                    onPressed: () => _submitRatingAndNavigate('صعب'),
                  ),
                  _buildRatingOption(
                    label: 'جيد',
                    bgColor: AppColors.brandPrimary,
                    textColor: Colors.white,
                    isSelected: savedMarkAsLabel == 'جيد',
                    onPressed: () => _submitRatingAndNavigate('جيد'),
                  ),
                  _buildRatingOption(
                    label: 'سهل',
                    bgColor: AppColors.success50,
                    textColor: AppColors.success700,
                    isSelected: savedMarkAsLabel == 'سهل',
                    onPressed: () => _submitRatingAndNavigate('سهل'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // زر "أضف إلى المكتبة"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAddedToLibrary || _isAdding
                      ? null
                      : _addToLibrary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAddedToLibrary
                        ? AppColors.gray300
                        : AppColors.gray200,
                    foregroundColor: _isAddedToLibrary
                        ? AppColors.gray500
                        : AppColors.gray800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        )
                      : Text(
                          _isAddedToLibrary
                              ? 'تمت الإضافة إلى المكتبة'
                              : 'أضف إلى المكتبة',
                          style: const TextStyle(
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

  // خيار تقييم مع زر + علامة صح أسفله
  Widget _buildRatingOption({
    required String label,
    required Color bgColor,
    required Color textColor,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الزر نفسه
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.brandPrimary, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brandPrimary.withOpacity(0.2),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // علامة الصح أسفل الزر
            const SizedBox(height: 8),
            if (isSelected)
              Icon(Icons.check_circle, size: 20, color: AppColors.brandPrimary),
          ],
        ),
      ),
    );
  }
}
