// lib/features/exam/views/exam_result_screen.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/days/views/days_view.dart';
import 'package:rawasi_app_n/features/exam/data/question_item.dart';
import 'package:rawasi_app_n/features/exam/views/review_questions_screen.dart';

class ExamResultScreen extends StatefulWidget {
  final List<String> selectedAnswers;
  final List<QuestionItem> questions;
  final int dayId;

  const ExamResultScreen({
    super.key,
    required this.selectedAnswers,
    required this.questions,
    required this.dayId,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  late int hardCount;
  late int goodCount;
  late int easyCount;
  late bool needsReview;

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  void _calculateResults() {
    hardCount = widget.selectedAnswers
        .where((answer) => answer == 'صعب')
        .length;
    goodCount = widget.selectedAnswers
        .where((answer) => answer == 'جيد')
        .length;
    easyCount = widget.selectedAnswers
        .where((answer) => answer == 'سهل')
        .length;
    needsReview = (hardCount + goodCount) > 0;
  }

  void _onReviewCompleted(List<String> updatedAnswers) {
    setState(() {
      for (int i = 0; i < updatedAnswers.length; i++) {
        widget.selectedAnswers[i] = updatedAnswers[i];
      }
      _calculateResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('تم الامتحان'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // مؤشر الحالة
                _buildStatusIndicator(),
                const SizedBox(height: 24),

                // الرسالة التحفيزية للمراجعة — الآن بألوان زرقاء!
                if (needsReview) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary50, // ← خلفية زرقاء فاتحة
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary200, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons
                                  .assignment_late_outlined, // ← أيقونة مناسبة للمراجعة
                              color: AppColors
                                  .brandPrimary, // ← لون أزرق علامة تجارية
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ملاحظة هامة',
                              style: TextStyle(
                                color: AppColors.brandPrimary, // ← نص أزرق داكن
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لابد من مراجعة الأسئلة التي تم اختيارها "صعب" و"جيد" وإعادة اختيارها "سهل" لكي تكمل المهمة بنجاح',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gray800, // ← نص رمادي داكن (محايد)
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // زر المراجعة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final reviewQuestions = widget.questions
                            .asMap()
                            .entries
                            .where(
                              (entry) =>
                                  widget.selectedAnswers[entry.key] == 'صعب' ||
                                  widget.selectedAnswers[entry.key] == 'جيد',
                            )
                            .map(
                              (entry) => ReviewQuestionItem(
                                index: entry.key,
                                questionItem: entry.value,
                                currentMark: widget.selectedAnswers[entry.key],
                              ),
                            )
                            .toList();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewQuestionsScreen(
                              reviewQuestions: reviewQuestions,
                              selectedAnswers: List<String>.from(
                                widget.selectedAnswers,
                              ),
                              dayId: widget.dayId,
                              onCompleted: _onReviewCompleted,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit_note_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'مراجعة الأسئلة',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // مؤشر احتفالي
                if (!needsReview) ...[
                  Icon(
                    Icons.celebration,
                    color: AppColors.brandPrimary,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                ],

                // رسالة التهاني
                Text(
                  needsReview
                      ? 'لديك ${hardCount + goodCount} سؤال يحتاج مراجعة'
                      : 'مبروك عليك! قد انتهيت من مادة شريعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: needsReview
                        ? AppColors
                              .brandPrimary // ← أزرق بدل ذهبي
                        : AppColors.brandPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اليوم الثاني - 23/07/2025 - شريعة',
                  style: TextStyle(color: AppColors.gray600, fontSize: 16),
                ),
                const SizedBox(height: 24),

                // بطاقات اليوم — بدون أصفر!
                Text(
                  'بطاقات اليوم',
                  style: TextStyle(
                    color: AppColors.brandSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRatingCard(
                      hardCount.toString(),
                      'صعب',
                      AppColors.primary50, // ← خلفية زرقاء فاتحة
                      AppColors.brandPrimary, // ← نص أزرق داكن
                    ),
                    _buildRatingCard(
                      goodCount.toString(),
                      'جيد',
                      AppColors.primary50,
                      AppColors.brandPrimary,
                    ),
                    _buildRatingCard(
                      easyCount.toString(),
                      'سهل',
                      AppColors.success50,
                      AppColors.success700,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // رسالة المستخدم
                if (needsReview) ...[
                  Text(
                    'ستتمكن من إكمال المهمة بعد تحويل جميع الأسئلة إلى "سهل"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.brandPrimary, // ← أزرق داكن
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Text(
                    'ستراجع البطاقات الصعبة في المرة القادمة ضمن الاختبارات',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gray600, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                ],

                // زر "تم"
                if (!needsReview)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DaysView(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'تم',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (!needsReview) {
      return Column(
        children: [
          Icon(Icons.check_circle, color: AppColors.success600, size: 64),
          const SizedBox(height: 8),
          Text(
            'مهمة مكتملة بنجاح!',
            style: TextStyle(
              color: AppColors.success700,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Icon(
          Icons.pending_actions,
          color: AppColors.brandPrimary, // ← أزرق بدل ذهبي
          size: 64,
        ),
        const SizedBox(height: 8),
        Text(
          'مهمة غير مكتملة',
          style: TextStyle(
            color: AppColors.brandPrimary, // ← أزرق داكن
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard(
    String count,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    final isNeedsReview = (label == 'صعب' || label == 'جيد') && count != '0';

    return Container(
      width: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: isNeedsReview
            ? Border.all(color: AppColors.primary300, width: 2) // ← حدود زرقاء
            : null,
        boxShadow: isNeedsReview
            ? [
                BoxShadow(
                  color: AppColors.primary100, // ← ظل أزرق فاتح
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: isNeedsReview ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewQuestionItem {
  final int index;
  final QuestionItem questionItem;
  final String currentMark;

  ReviewQuestionItem({
    required this.index,
    required this.questionItem,
    required this.currentMark,
  });
}
