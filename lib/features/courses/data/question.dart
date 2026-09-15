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
}
