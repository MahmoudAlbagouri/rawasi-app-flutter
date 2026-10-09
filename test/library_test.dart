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
        SubjectItem.fromJson({
          'id': 1,
          'name': 'x',
          'saved_questions_count': '4',
        }).savedQuestionsCount,
        4,
      );
    });

    test('a missing count is zero, not a crash', () {
      expect(
        SubjectItem.fromJson({'id': 1, 'name': 'x'}).savedQuestionsCount,
        0,
      );
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
      expect(
        _item(type: 'fiqh_application').libraryable.typeLabel,
        'تطبيق فقهي',
      );
    });

    test('a free-text type is shown as written', () {
      // Admins can type their own types ("أكمل الآية") in the dashboard.
      expect(_item(type: 'أكمل الآية').libraryable.typeLabel, 'أكمل الآية');
      expect(_item(type: '  أكمل الآية ').libraryable.typeLabel, 'أكمل الآية');
    });

    test('a missing or blank type falls back to a neutral label', () {
      expect(_item(type: '').libraryable.typeLabel, 'سؤال');
      expect(
        ContentItem.fromJson({
          'id': 1,
          'libraryable': {'id': 2, 'question': 'س', 'correct_answer': 'ج'},
        }).libraryable.typeLabel,
        'سؤال',
      );
    });

    test(
      'falls back to task_title when the nested question text is missing',
      () {
        final item = ContentItem.fromJson({
          'id': 1,
          'task_title': 'نص السؤال',
          'libraryable': {'id': 2, 'correct_answer': 'ج'},
        });

        expect(item.questionText, 'نص السؤال');
      },
    );
  });

  group('PDF export', () {
    // rootBundle serves assets declared in pubspec.yaml under flutter_test.
    TestWidgetsFlutterBinding.ensureInitialized();

    test('refuses to build a document with no questions', () {
      expect(
        () => LibraryPdf.shareSubject(
          subjectName: 'التفسير',
          questions: const [],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('produces a real PDF carrying the Arabic subject name', () async {
      final bytes = await LibraryPdf.build(
        subjectName: 'التفسير',
        questions: [
          _item(question: 'ما معنى الإحسان؟', answer: 'أن تعبد الله كأنك تراه'),
          _item(
            id: 8,
            question: 'عرّف الصلاة',
            answer: 'أقوال وأفعال مفتتحة بالتكبير',
          ),
        ],
      );

      // A PDF, not an empty or truncated buffer.
      expect(utf8.decode(bytes.sublist(0, 5), allowMalformed: true), '%PDF-');
      expect(bytes.length, greaterThan(2000));

      // Arabic is laid out by Flutter's text engine and embedded as images —
      // the pdf package's own shaper drops letters Tajawal has no legacy
      // presentation-form glyph for. Only digits remain PDF text, in Tajawal.
      final raw = latin1.decode(bytes, allowInvalid: true);
      expect(
        raw.contains('/Subtype /Image') || raw.contains('/Subtype/Image'),
        isTrue,
        reason: 'Arabic runs are expected as rendered images',
      );
      expect(
        raw.contains('Tajawal'),
        isTrue,
        reason: 'page numbers are set in the embedded Tajawal font',
      );
    });

    // Regression: the pdf package mapped the isolated ي and أ to presentation
    // forms Tajawal lacks (U+FEF1, U+FE83) and drew nothing, so "أي: الذي"
    // printed as "أ:" and "الذ". Flutter's engine must draw those letters.
    test('letters the old PDF shaper dropped are drawn', () async {
      expect(
        await LibraryPdf.debugTextWidth('الذي'),
        greaterThan(await LibraryPdf.debugTextWidth('الذ')),
        reason: 'the final ي of الذي must take up space',
      );
      expect(
        await LibraryPdf.debugTextWidth('أي'),
        greaterThan(await LibraryPdf.debugTextWidth('أ')),
        reason: 'the ي after a non-joining أ must take up space',
      );
    });

    test('scales to a long subject without falling over', () async {
      final many = List.generate(
        40,
        (i) => _item(id: i, question: 'سؤال رقم $i'),
      );

      final bytes = await LibraryPdf.build(
        subjectName: 'الفقه',
        questions: many,
      );

      expect(bytes.length, greaterThan(5000));
    });

    // The document direction must reach the text layout: RTL Arabic is laid
    // out (and aligned) differently from LTR, so the two outputs must differ.
    test('Arabic is laid out right-to-left', () async {
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

      expect(
        latin1.decode(rtl, allowInvalid: true),
        isNot(equals(latin1.decode(ltr, allowInvalid: true))),
        reason:
            'RTL must change the rendered text - otherwise direction was ignored',
      );
      expect(await lengthFor(pw.TextDirection.rtl), greaterThan(0));
    });

    test(
      'the answer sheet is the same questions without the answers',
      () async {
        final questions = [
          _item(question: 'ما معنى الإحسان؟', answer: 'أن تعبد الله كأنك تراه'),
          _item(
            id: 8,
            question: 'عرّف الصلاة',
            answer: 'أقوال وأفعال مفتتحة بالتكبير',
          ),
        ];

        final withAnswers = await LibraryPdf.build(
          subjectName: 'التفسير',
          questions: questions,
        );
        final sheet = await LibraryPdf.build(
          subjectName: 'التفسير',
          questions: questions,
          mode: LibraryPdfMode.answerSheet,
        );

        expect(utf8.decode(sheet.sublist(0, 5), allowMalformed: true), '%PDF-');
        expect(sheet, isNot(equals(withAnswers)));
        // Default is unchanged: the original export, with answers.
        expect(
          await LibraryPdf.build(subjectName: 'التفسير', questions: questions),
          hasLength(withAnswers.length),
        );
      },
    );

    test('the blank space grows with the model answer, within limits', () {
      expect(
        LibraryPdf.blankLinesFor(0),
        2,
        reason: 'never fewer than 2 lines',
      );
      expect(LibraryPdf.blankLinesFor(15), 2);
      expect(
        LibraryPdf.blankLinesFor(100),
        greaterThan(LibraryPdf.blankLinesFor(15)),
      );
      expect(
        LibraryPdf.blankLinesFor(5000),
        10,
        reason: 'never more than 10 lines',
      );
    });

    // At least 6 typical questions with their answers per page (the first
    // layout fit 3-4). Measured on real curriculum content; pinned here so a
    // later style tweak cannot quietly bring the old density back.
    test('fits at least 6 typical questions with answers on a page', () async {
      final typical = List.generate(
        12,
        (i) => _item(
          id: i + 1,
          question: 'بيّن معنى قوله تعالى في الآية رقم ${i + 1} من السورة.',
          answer:
              'المقصود بها التوجه بالاعتصام بحبل الله ونبذ الخلافات والفرقة.',
        ),
      );

      final bytes = await LibraryPdf.build(
        subjectName: 'التفسير',
        questions: typical,
      );
      final pages = RegExp(
        r'/Type\s*/Page[^s]',
      ).allMatches(latin1.decode(bytes, allowInvalid: true)).length;

      expect(
        pages,
        lessThanOrEqualTo(2),
        reason: '12 questions at 6+ per page',
      );
    });

    test('formats the export date in Arabic', () {
      expect(
        LibraryPdf.formatArabicDate(DateTime(2026, 9, 24)),
        '24 سبتمبر 2026',
      );
      expect(LibraryPdf.formatArabicDate(DateTime(2026, 1, 1)), '1 يناير 2026');
    });
  });
}
