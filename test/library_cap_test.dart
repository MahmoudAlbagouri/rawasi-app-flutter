import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/contact/data/contact_message.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';

/// The library holds at most N questions per subject. The server enforces it;
/// these fields are what let the app say so BEFORE the student is refused.
SubjectItem _subject({required int saved, int? max}) => SubjectItem.fromJson({
      'id': 3,
      'name': 'التفسير',
      'saved_questions_count': saved,
      if (max != null) 'max_saved_questions': max,
    });

void main() {
  group('the per-subject cap', () {
    test('is carried alongside the count', () {
      final s = _subject(saved: 95, max: 100);

      expect(s.savedQuestionsCount, 95);
      expect(s.maxSavedQuestions, 100);
      expect(s.remainingSlots, 5);
      expect(s.isFull, isFalse);
    });

    test('is full exactly at the cap, not one past it', () {
      expect(_subject(saved: 99, max: 100).isFull, isFalse);
      expect(_subject(saved: 100, max: 100).isFull, isTrue);
    });

    test('a subject already over the cap is full with nothing remaining', () {
      // Possible after the cap is LOWERED. Nothing is deleted, so the count can
      // exceed the limit, and `remainingSlots` must not go negative.
      final s = _subject(saved: 140, max: 100);

      expect(s.isFull, isTrue);
      expect(s.remainingSlots, 0);
    });
  });

  group('a missing cap', () {
    test('is null, never zero', () {
      // Zero would read as "nothing may be saved" — the exact opposite of "no
      // cap known" — and would show every subject as full.
      final s = _subject(saved: 12);

      expect(s.maxSavedQuestions, isNull);
      expect(s.isFull, isFalse);
      expect(s.remainingSlots, isNull);
    });

    test('an explicit null is treated the same as absent', () {
      final s = SubjectItem.fromJson({
        'id': 1,
        'name': 'الفقه',
        'saved_questions_count': 4,
        'max_saved_questions': null,
      });

      expect(s.maxSavedQuestions, isNull);
      expect(s.isFull, isFalse);
    });
  });

  group('copyWith', () {
    test('keeps the cap when only the count changes', () {
      // Removing a question updates the count locally, with no round trip. If
      // the cap were dropped here the subject would stop reporting itself as
      // full — or as not full — correctly.
      final updated = _subject(saved: 100, max: 100).copyWith(
        savedQuestionsCount: 99,
      );

      expect(updated.maxSavedQuestions, 100);
      expect(updated.isFull, isFalse, reason: 'a slot was just freed');
    });
  });

  group('fullness is derived, not trusted', () {
    test('is recomputed from the counts rather than read from the payload', () {
      // The API also sends `is_full`. Reading that flag instead would leave it
      // stale after a local copyWith — the subject would still claim to be full
      // after a question was removed.
      final s = SubjectItem.fromJson({
        'id': 1,
        'name': 'الحديث',
        'saved_questions_count': 2,
        'max_saved_questions': 100,
        'is_full': true, // deliberately contradicts the counts
      });

      expect(s.isFull, isFalse);
    });
  });

  group('question feedback in the message list', () {
    test('a note about a question carries the question back', () {
      final m = ContactMessage.fromJson({
        'id': 9,
        'message': 'الإجابة غير صحيحة',
        'reply': 'تم التصحيح، شكرًا لك',
        'created_at': '2026-10-01T10:00:00+00:00',
        'question_id': 42,
        'question': 'ما حكم كذا؟',
      });

      expect(m.isAboutQuestion, isTrue);
      expect(m.questionId, 42);
      expect(m.question, 'ما حكم كذا؟');
      expect(m.reply, 'تم التصحيح، شكرًا لك');
    });

    test('an ordinary enquiry is not about a question', () {
      final m = ContactMessage.fromJson({
        'id': 10,
        'message': 'متى تُفتح باقي الدروس؟',
        'created_at': '2026-10-01T10:00:00+00:00',
      });

      expect(m.isAboutQuestion, isFalse);
      expect(m.questionId, isNull);
      expect(m.question, isNull);
    });

    test('question_id arrives as a STRING without crashing the parse', () {
      // THE REPORTED BUG: the app posted question_id inside a JSON body as a
      // string, Eloquent echoed the attribute straight back out as the string
      // it came in as, and `json['question_id'] as int?` threw a TypeError —
      // so a note that HAD been saved was reported as "تعذّر إرسال الملاحظة".
      //
      // The server casts it now, but an app in the wild talks to whatever
      // backend is deployed, so the parser must survive either type.
      final m = ContactMessage.fromJson({
        'id': '9',
        'message': 'ملاحظة',
        'created_at': '2026-10-01T10:00:00+00:00',
        'question_id': '4821',
      });

      expect(m.questionId, 4821);
      expect(m.id, 9);
      expect(m.isAboutQuestion, isTrue);
    });

    test('an unparseable id degrades to unknown rather than throwing', () {
      final m = ContactMessage.fromJson({
        'id': 9,
        'message': 'ملاحظة',
        'created_at': '2026-10-01T10:00:00+00:00',
        'question_id': 'not-a-number',
      });

      expect(m.questionId, isNull);
      expect(m.isAboutQuestion, isFalse);
    });

    test('a malformed date does not take the whole list down', () {
      // This list is the only place a student reads an admin's reply, so one bad
      // field must not throw past the parse.
      final m = ContactMessage.fromJson({
        'id': 11,
        'message': 'رسالة',
        'created_at': 'not-a-date',
      });

      expect(m.message, 'رسالة');
    });
  });
}
