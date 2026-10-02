// lib/features/contact/data/contact_repo.dart
//
// Support messages, both kinds:
//
//   - a general enquiry from تواصل معنا (no question attached), and
//   - a note written against one question from inside a lesson.
//
// They share an endpoint on purpose. /contact-support already has the admin
// inbox, the reply field and a student-facing list of past messages with their
// replies; question feedback is the same conversation with one extra piece of
// context, so it travels as one extra field rather than as a second system
// nobody would have built a dashboard for.
//
// ContactView still has its own inline Dio calls. They are left alone here to
// keep this change small; new callers use this repo, which is where the
// `ApiServices` convention points.

import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/contact/data/contact_message.dart';

class ContactRepo {
  final ApiServices _api = ApiServices();

  /// Sends a note about one question.
  ///
  /// [questionId] is validated server-side against what this student can
  /// actually see, so a rejection here is a real refusal and its message is
  /// worth showing.
  Future<ContactMessage> sendQuestionFeedback({
    required int questionId,
    required String message,
  }) async {
    return _send({
      'message': message,
      // A number, not a string. Sending "4821" was harmless to validation but
      // it is what Eloquent echoed straight back as a string, which the model
      // parser then choked on. Send the right type and the round trip is clean
      // whatever the server does with it.
      'question_id': questionId,
    });
  }

  /// Sends a general support message, with no question attached.
  Future<ContactMessage> sendMessage(String message) =>
      _send({'message': message});

  Future<ContactMessage> _send(Map<String, dynamic> body) async {
    final result = await _api.post('/contact-support', body);

    // ApiServices RETURNS an ApiError instead of throwing it, so a 422 arrives
    // here as a value. Without this line the server's own message - "هذا السؤال
    // غير متاح لك", the validation text - would be replaced by the generic
    // fallback below, and the student would be told nothing useful.
    if (result is ApiError) throw result;

    if (result is Map<String, dynamic> && result['success'] == true) {
      final data = result['data'];
      if (data is Map<String, dynamic>) return ContactMessage.fromJson(data);

      // Shape changed or the endpoint answered without a body. The message was
      // accepted, which is what the caller asked about, so this is not an error.
      return ContactMessage(
        id: 0,
        message: body['message']?.toString() ?? '',
        createdAt: DateTime.now(),
      );
    }

    // `success: false` is an error whatever the HTTP status says — the envelope
    // is the contract here, not the status code.
    throw ApiError(
      message: result is Map && result['message'] is String
          ? result['message'] as String
          : 'تعذّر إرسال الرسالة',
    );
  }

  /// This student's past messages, newest first, with any replies.
  Future<List<ContactMessage>> fetchMessages() async {
    final result = await _api.get('/my-contact-support');

    if (result is ApiError) throw result;

    if (result is Map<String, dynamic> && result['success'] == true) {
      final list = result['data'] as List<dynamic>? ?? const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ContactMessage.fromJson)
          .toList();
    }

    throw ApiError(
      message: result is Map && result['message'] is String
          ? result['message'] as String
          : 'تعذّر تحميل الرسائل',
    );
  }
}
