import 'package:rawasi_app_n/features/exam/data/daily_task_item.dart';

class QuestionItem {
  final int dailyTaskId;
  final int questionId;
  final int courseId;
  final String question;
  final String answer;
  final bool isCompleted;
  final String? markAs;
  final String? questionType; // ← الحقل الجديد

  QuestionItem({
    required this.dailyTaskId,
    required this.questionId,
    required this.courseId,
    required this.question,
    required this.answer,
    this.isCompleted = false,
    this.markAs,
    this.questionType, // ← إضافة هنا
  });

  factory QuestionItem.fromDailyTaskItem(DailyTaskItem item) {
    final dayable = item.dayable;
    final questionId = dayable.questionId ?? 0;
    final courseId = dayable.courseId ?? 0;

    if (questionId == 0) {
      throw Exception('question_id مفقود في استجابة السؤال');
    }
    if (courseId == 0) {
      throw Exception('course_id مفقود في استجابة السؤال');
    }

    return QuestionItem(
      dailyTaskId: item.id,
      questionId: questionId,
      courseId: courseId,
      question: dayable.question ?? 'لا يوجد سؤال',
      answer: dayable.answer ?? 'لا يوجد إجابة',
      isCompleted: dayable.isCompleted,
      markAs: dayable.markAs,
      questionType: dayable.questionType, // ← تمرير القيمة
    );
  }
}
