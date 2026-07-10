// lib/features/contact/models/contact_message.dart

class ContactMessage {
  final int id;
  final String message;
  final String? reply;
  final DateTime createdAt;

  ContactMessage({
    required this.id,
    required this.message,
    this.reply,
    required this.createdAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] as int,
      message: json['message'] as String,
      reply: json['reply'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
