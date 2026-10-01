// lib/features/contact/models/contact_message.dart

class ContactMessage {
  final int id;
  final String message;
  final String? reply;
  final DateTime createdAt;

  /// Set when this message was written about one question from inside a lesson,
  /// null for a general enquiry — which is most of them.
  final int? questionId;

  /// The question's text, so the list of past messages can show what a note was
  /// about instead of an orphaned sentence. Null when the API did not send it.
  final String? question;

  ContactMessage({
    required this.id,
    required this.message,
    this.reply,
    required this.createdAt,
    this.questionId,
    this.question,
  });

  /// True when this message is feedback on a specific question.
  bool get isAboutQuestion => questionId != null;

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      // Parsed defensively throughout. This list is the only place a student
      // sees an admin's reply, so one unexpected field must not take the whole
      // screen down with it.
      id: json['id'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      reply: json['reply'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      questionId: json['question_id'] as int?,
      question: json['question'] as String?,
    );
  }
}
