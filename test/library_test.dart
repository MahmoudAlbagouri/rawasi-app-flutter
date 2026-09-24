import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:rawasi_app_n/features/library/data/content_item.dart';
import 'package:rawasi_app_n/features/library/data/library_pdf.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';

/// One row exactly as LibraryResource now returns it.
ContentItem _item({
  int id = 7,
  String question = 'ما معنى الإحسان؟',
  String answer = 'أن تعبد الله كأنك تراه',
  String type = 'definitions',
}) {
  return ContentItem.fromJson({
    'id': id,
    'type': 'question',
    'task_title': question,
    'libraryable': {
      'id': 99,
      'question': question,
      'correct_answer': answer,
      'type': type,
    },
    'course': 'التفسير',
    'created_at': '2026-09-24 10:00:00',
  });
}

void main() {
  group('SubjectItem', () {
    test('reads the per-student saved count', () {
      final s = SubjectItem.fromJson({
        'id': 3,
        'name': 'الحديث',
        'saved_questions_count': 12,
      });

      expect(s.id, 3);
      expect(s.name, 'الحديث');
      expect(s.savedQuestionsCount, 12);
    });

    test('a count sent as a string still parses', () {
      expect(
        SubjectItem.fromJson({'id': 1, 'name': 'x', 'saved_questions_count': '4'})
            .savedQuestionsCount,
        4,
      );
    });

    test('a missing count is zero, not a crash', () {
      expect(SubjectItem.fromJson({'id': 1, 'name': 'x'}).savedQuestionsCount, 0);
    });
  });

  group('ContentItem', () {
    test('course and task_title are read, not left empty', () {
      // Both fields were always '' until LibraryResource stopped reading a
      // misspelled relation and a column Questions do not have.
      final item = _item();

      expect(item.course, 'التفسير');
      expect(item.taskTitle, 'ما معنى الإحسان؟');
      expect(item.questionText, 'ما معنى الإحسان؟');
      expect(item.answerText, 'أن تعبد الله كأنك تراه');
    });

    test('the id is the LIBRARY row id, not the question id', () {
      // DELETE /remove-from-library/{id} takes the library row.
      final item = _item(id: 7);

      expect(item.id, 7);
      expect(item.libraryable.id, 99);
    });

    test('the question type is labelled in Arabic, never the raw enum', () {
      expect(_item(type: 'definitions').libraryable.typeLabel, 'عرّف');
      expect(_item(type: 'true_false').libraryable.typeLabel, 'صح وخطأ');
      expect(_item(type: 'fiqh_application').libraryable.typeLabel, 'تطبيق فقهي');
    });

    test('an unknown or missing type falls back to a neutral label', () {
      expect(_item(type: 'something_new').libraryable.typeLabel, 'سؤال');
      expect(
        ContentItem.fromJson({
          'id': 1,
          'libraryable': {'id': 2, 'question': 'س', 'correct_answer': 'ج'},
        }).libraryable.typeLabel,
        'سؤال',
      );
    });

    test('falls back to task_title when the nested question text is missing', () {
      final item = ContentItem.fromJson({
        'id': 1,
        'task_title': 'نص السؤال',
        'libraryable': {'id': 2, 'correct_answer': 'ج'},
      });

      expect(item.questionText, 'نص السؤال');
    });
  });

  group('PDF export', () {
    // rootBundle serves assets declared in pubspec.yaml under flutter_test.
    TestWidgetsFlutterBinding.ensureInitialized();

    test('refuses to build a document with no questions', () {
      expect(
        () => LibraryPdf.shareSubject(subjectName: 'التفسير', questions: const []),
        throwsA(isA<StateError>()),
      );
    });

    test('produces a real PDF carrying the Arabic subject name', () async {
      final bytes = await LibraryPdf.build(
        subjectName: 'التفسير',
        questions: [
          _item(question: 'ما معنى الإحسان؟', answer: 'أن تعبد الله كأنك تراه'),
          _item(id: 8, question: 'عرّف الصلاة', answer: 'أقوال وأفعال مفتتحة بالتكبير'),
        ],
      );

      // A PDF, not an empty or truncated buffer.
      expect(utf8.decode(bytes.sublist(0, 5), allowMalformed: true), '%PDF-');
      expect(bytes.length, greaterThan(2000));

      // The Arabic font is what makes Arabic render instead of boxes, so
      // assert the TTF actually got embedded rather than silently skipped.
      final raw = latin1.decode(bytes, allowInvalid: true);
      expect(raw.contains('Tajawal'), isTrue,
          reason: 'the Arabic TTF must be embedded or every glyph is a box');
      expect(raw.contains('FontFile2'), isTrue,
          reason: 'an embedded TrueType font program is expected');
    });

    test('scales to a long subject without falling over', () async {
      final many = List.generate(40, (i) => _item(id: i, question: 'سؤال رقم $i'));

      final bytes = await LibraryPdf.build(subjectName: 'الفقه', questions: many);

      expect(bytes.length, greaterThan(5000));
    });

    // The whole point of the client-side route: without RTL the pdf package
    // never calls arabic.convert, and the letters come out unjoined and
    // reversed. Building the same content both ways must therefore differ.
    test('Arabic is shaped right-to-left, not laid out as-is', () async {
      Future<int> lengthFor(pw.TextDirection d) async {
        final bytes = await LibraryPdf.build(
          subjectName: 'التفسير',
          questions: [_item(question: 'ما معنى الإحسان في الإسلام؟')],
          direction: d,
        );
        return bytes.length;
      }

      final rtl = await LibraryPdf.build(
        subjectName: 'التفسير',
        questions: [_item(question: 'ما معنى الإحسان في الإسلام؟')],
        direction: pw.TextDirection.rtl,
      );
      final ltr = await LibraryPdf.build(
        subjectName: 'التفسير',
        questions: [_item(question: 'ما معنى الإحسان في الإسلام؟')],
        direction: pw.TextDirection.ltr,
      );

      expect(latin1.decode(rtl, allowInvalid: true),
          isNot(equals(latin1.decode(ltr, allowInvalid: true))),
          reason: 'RTL must change the emitted glyph run - otherwise no shaping ran');
      expect(await lengthFor(pw.TextDirection.rtl), greaterThan(0));
    });

    test('formats the export date in Arabic', () {
      expect(LibraryPdf.formatArabicDate(DateTime(2026, 9, 24)), '24 سبتمبر 2026');
      expect(LibraryPdf.formatArabicDate(DateTime(2026, 1, 1)), '1 يناير 2026');
    });
  });
}
