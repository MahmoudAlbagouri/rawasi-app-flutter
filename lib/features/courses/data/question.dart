/// Arabic labels for the backend's QuestionType enum (App\Enums\QuestionType).
/// Keep in sync with it — an unknown key falls back to a neutral label.
const Map<String, String> _questionTypeLabels = {
  'multiple_choice': 'اختر',
  'fill_in_the_blank': 'أكمل',
  'explanation': 'اشرح',
  'reasoning': 'علل',
  'comparison': 'قارن',
  'definitions': 'عرّف',
  'rulings_extraction': 'استخرج الأحكام',
  'true_false': 'صح وخطأ',
  'meaning': 'ما المقصود',
  'ordering': 'رتّب',
  'classification': 'صنّف',
  'fiqh_application': 'تطبيق فقهي',
  'benefits_extraction': 'استخرج الفوائد',
  'grammar_analysis': 'إعراب وتحليل',
  'memorization': 'استظهار',
};

class Question {
  final int questionId;
  final int lessonId;
  final String type;
  final String question;
  final String answer;
  final bool isCompleted;

  Question({
    required this.questionId,
    required this.lessonId,
    required this.type,
    required this.question,
    required this.answer,
    required this.isCompleted,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['question_id'] as int? ?? 0,
      lessonId: json['lesson_id'] as int? ?? 0,
      type: json['type'] as String? ?? 'text',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      isCompleted: json['is_completed'] == true,
    );
  }

  String get typeLabel => _questionTypeLabels[type] ?? 'سؤال';
}
