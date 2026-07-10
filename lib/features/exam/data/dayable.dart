class Dayable {
  final int id;
  final int? questionId;
  final int? videoId;
  final int? courseId;
  final String type;
  final bool isCompleted;
  final String? markAs;
  final String? question;
  final String? answer;
  final String? title;
  final String? questionType; // ← الحقل الجديد

  Dayable({
    required this.id,
    this.questionId,
    this.videoId,
    this.courseId,
    required this.type,
    required this.isCompleted,
    this.markAs,
    this.question,
    this.answer,
    this.title,
    this.questionType, // ← إضافة هنا
  });

  factory Dayable.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?)?.toLowerCase() ?? '';

    return Dayable(
      id: json['id'] ?? 0,
      questionId: json['question_id'],
      videoId: json['video_id'],
      courseId: json['course_id'],
      type: type,
      isCompleted: json['is_completed'] ?? false,
      markAs: json['mark_as'],
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      title: json['title'] as String?,
      questionType: json['question_type'] as String?, // ← قراءة من الـ API
    );
  }
}
