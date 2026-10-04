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
      id: _int(json['id']) ?? 0,
      message: json['message']?.toString() ?? '',
      reply: json['reply']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      questionId: _int(json['question_id']),
      question: json['question']?.toString(),
    );
  }

  /// Numbers arrive as int OR String from this API and must not be cast blind.
  ///
  /// THE BUG THIS FIXES: `json['question_id'] as int?` threw a TypeError on the
  /// response to a freshly POSTed note. The app sends question_id inside a JSON
  /// body, Eloquent handed the value straight back out as the string it came in
  /// as, and the cast blew up — so a note that HAD been saved was reported to
  /// the student as "تعذّر إرسال الملاحظة".
  ///
  /// The server now casts it too, but this stays: an app in the wild talks to
  /// whatever version of the backend is deployed, and a type mismatch must
  /// degrade to "unknown", never to a crash.
  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();

    return int.tryParse(v.toString());
  }
}
