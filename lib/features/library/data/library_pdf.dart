// lib/features/library/data/library_pdf.dart
//
// "استخراج PDF" for one library subject.
//
// Generated CLIENT-SIDE. The questions are already in memory once the subject
// has been opened, so this needs no new endpoint, no auth on a binary response
// and no download handling — and it works with no connection.
//
// ARABIC IS DRAWN BY FLUTTER, NOT BY THE PDF PACKAGE.
//
// The pdf package shapes Arabic itself, by rewriting each letter to its legacy
// "presentation form" codepoint (U+FExx) and drawing that glyph from the font.
// Tajawal — the app's font — carries only 89 of those codepoints, because
// modern fonts shape through OpenType tables instead. Two it lacks are the
// isolated ي (U+FEF1) and the isolated أ (U+FE83), and the pdf package draws a
// missing glyph as nothing. So "أي: الذي" came out as "أ:" crashed into the
// previous word and "الذ", with spaces around them swallowed too. It also does
// no mark positioning, which matters for Quranic text with tashkeel.
//
// Flutter's own text engine shapes through the font's OpenType tables — the
// same path every screen in the app uses — so each Arabic run is laid out by
// it and embedded as a high-resolution image. Boxes, colours and page breaks
// stay real PDF; only the Arabic glyphs are raster. The trade-off is that the
// Arabic text is not selectable in the PDF, which for a printable revision
// sheet is the right price for every letter being present and correct.
//
// Only bare digits (the page numbers) are still set as PDF text: digits need
// no shaping, so the pdf package renders them correctly.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';

/// Brand colour, kept in step with AppColors.brandPrimary (#135E8D).
const PdfColor _brand = PdfColor.fromInt(0xFF135E8D);
const PdfColor _ink = PdfColor.fromInt(0xFF1F2937);
const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
const PdfColor _tint = PdfColor.fromInt(0xFFF1F6FA);

// Page geometry, in PDF points. Text images are laid out to exactly the width
// of the box they sit in, so these must match the paddings used below.
const double _pageMargin = 32;
const double _contentWidth = 595.28 - _pageMargin * 2; // A4 minus margins
const double _titleTextWidth = _contentWidth - 16 * 2 - 2; // padding + border
const double _blockInner = _contentWidth - 14 * 2 - 2;
const double _questionTextWidth = _blockInner - 22 - 8; // number badge + gap
const double _answerTextWidth = _blockInner - 10 * 2;

/// The two library exports.
enum LibraryPdfMode {
  /// Each question with its model answer — the original export.
  withAnswers,

  /// The same questions with NO answers: a blank, ruled space under each one,
  /// to print and solve on paper.
  answerSheet,
}

class LibraryPdf {
  /// Thrown rather than producing a document with no questions in it.
  static const String emptyMessage = 'لا توجد أسئلة محفوظة في هذه المادة.';

  /// Rendering resolution of the text images: 3 px per PDF point ≈ 216 dpi,
  /// sharp on screen and in print.
  static const double _scale = 3;

  /// A family name of our own, registered here with FontLoader, so the
  /// rasteriser never depends on how (or whether) the app registered Tajawal.
  static const String _family = 'RawasiPdfTajawal';
  static Future<void>? _fontsReady;

  /// Builds the PDF and opens the system share/save sheet.
  ///
  /// Returns false if the student dismissed the sheet without saving or
  /// sharing, so the caller can stay quiet instead of claiming success.
  static Future<bool> shareSubject({
    required String subjectName,
    required List<ContentItem> questions,
    LibraryPdfMode mode = LibraryPdfMode.withAnswers,
  }) async {
    if (questions.isEmpty) {
      throw StateError(emptyMessage);
    }

    final bytes = await build(
      subjectName: subjectName,
      questions: questions,
      mode: mode,
    );

    return Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(subjectName, mode),
    );
  }

  /// Ruled lines left for the student's answer on the answer sheet: sized
  /// from the model answer, so a long answer gets room to be written out and a
  /// one-word one does not waste half a page. Never fewer than 3, never more
  /// than 12.
  @visibleForTesting
  static int blankLinesFor(double modelAnswerHeight) =>
      ((modelAnswerHeight / _ruleSpacing).ceil() + 1).clamp(3, 12);

  static const double _ruleSpacing = 24;

  /// The document itself, split out so it can be built and inspected without
  /// touching the platform share sheet.
  ///
  /// [direction] exists only so a test can build the same document LTR and
  /// prove it is honoured. Production always uses the default.
  static Future<Uint8List> build({
    required String subjectName,
    required List<ContentItem> questions,
    LibraryPdfMode mode = LibraryPdfMode.withAnswers,
    @visibleForTesting pw.TextDirection direction = pw.TextDirection.rtl,
  }) async {
    final sheet = mode == LibraryPdfMode.answerSheet;

    await _ensureFonts();

    final dir = direction == pw.TextDirection.rtl
        ? ui.TextDirection.rtl
        : ui.TextDirection.ltr;

    // pw.MultiPage builds synchronously, so every Arabic run is rendered up
    // front. Each question needs two images: its question and its answer.
    final exportedOn = formatArabicDate(DateTime.now());
    final title = await _textImage(
      [
        _Run(
          sheet ? 'أسئلتي المحفوظة — ورقة حل\n' : 'أسئلتي المحفوظة\n',
          size: 12,
          color: _muted,
        ),
        _Run('$subjectName\n', size: 22, color: _brand, bold: true),
        _Run(
          'عدد الأسئلة: ${questions.length}   •   تاريخ الاستخراج: $exportedOn',
          size: 11,
          color: _ink,
        ),
      ],
      width: _titleTextWidth,
      direction: dir,
    );
    final header = await _textImage([
      _Run(subjectName, size: 10, color: _muted),
    ], direction: dir);
    final pageWord = await _textImage([
      _Run('صفحة', size: 9, color: _muted),
    ], direction: dir);
    final ofWord = await _textImage([
      _Run('من', size: 9, color: _muted),
    ], direction: dir);

    final blocks = <pw.Widget>[];
    for (var i = 0; i < questions.length; i++) {
      final item = questions[i];
      final question = await _textImage(
        [
          _Run('${item.libraryable.typeLabel}\n', size: 9, color: _brand),
          _Run(item.questionText, size: 13, color: _ink, bold: true),
        ],
        width: _questionTextWidth,
        direction: dir,
      );
      final answer = await _textImage(
        [
          _Run('الإجابة\n', size: 9, color: _muted),
          _Run(
            item.answerText.isEmpty ? 'غير متوفرة' : item.answerText,
            size: 12,
            color: _ink,
          ),
        ],
        width: _answerTextWidth,
        direction: dir,
      );
      // On the answer sheet the model answer is only MEASURED, never printed:
      // its height decides how much blank space to leave.
      final lines = blankLinesFor(_imageHeight(answer));
      // A FRESH label per question: a pdf widget keeps its laid-out position on
      // the instance, so one instance reused under several questions on the
      // same page puts every copy but the last in the wrong place.
      final answerArea = sheet
          ? _blankAnswerArea(
              await _textImage([
                _Run('إجابتك:', size: 9, color: _muted),
              ], direction: dir),
              lines,
            )
          : answer;
      final answerHeight = sheet
          ? 18 + lines * _ruleSpacing
          : _imageHeight(answer);

      final block = _questionBlock(i + 1, question, answerArea, blank: sheet);

      // pw.Container forwards "may split across pages" to the Column inside
      // it, so a block landing at the foot of a page was cut in two — leaving
      // an empty bordered sliver behind. Keep each question whole on one page.
      // A block taller than a page (an extremely long answer) is left free to
      // split, since the only alternative would be failing the whole export.
      final fitsOnAPage =
          _imageHeight(question) + answerHeight + 70 <
          PdfPageFormat.a4.height - 72 - 60;
      blocks.add(fitsOnAPage ? pw.Inseparable(child: block) : block);
    }

    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(_pageMargin, 36, _pageMargin, 36),
        textDirection: direction,
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: direction == pw.TextDirection.rtl
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: header,
              ),
        // "صفحة 2 من 5": the two words are images, the numbers real text —
        // only the numbers change from page to page.
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pageWord,
            _digits(context.pageNumber),
            ofWord,
            _digits(context.pagesCount),
          ],
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _tint,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: _brand, width: 0.8),
            ),
            child: title,
          ),
          pw.SizedBox(height: 18),
          ...blocks,
        ],
      ),
    );

    return doc.save();
  }

  static double _imageHeight(pw.Widget w) => (w as pw.Image).height ?? 0;

  static pw.Widget _digits(int value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4),
    child: pw.Text(
      '$value',
      style: const pw.TextStyle(fontSize: 9, color: _muted),
    ),
  );

  /// Ruled writing lines under "إجابتك:" for the answer sheet.
  static pw.Widget _blankAnswerArea(pw.Widget label, int lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        label,
        for (var i = 0; i < lines; i++)
          pw.Container(
            height: _ruleSpacing,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _questionBlock(
    int number,
    pw.Widget question,
    pw.Widget answer, {
    bool blank = false,
  }) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 22,
                height: 22,
                alignment: pw.Alignment.center,
                decoration: const pw.BoxDecoration(
                  color: _brand,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  '$number',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              question,
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              // White on the answer sheet: it is written on with a pen.
              color: blank ? PdfColors.white : _tint,
              borderRadius: pw.BorderRadius.circular(6),
              border: blank
                  ? pw.Border.all(color: PdfColors.grey300, width: 0.5)
                  : null,
            ),
            child: answer,
          ),
        ],
      ),
    );
  }

  static Future<void> _ensureFonts() {
    return _fontsReady ??=
        (FontLoader(_family)
              ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
              ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf')))
            .load()
            .catchError((Object e) {
              _fontsReady =
                  null; // let the next export retry rather than stay broken
              throw e;
            });
  }

  /// Lays [runs] out with Flutter's text engine at [width] PDF points (or at
  /// its natural width when null) and returns it as a PDF image of exactly
  /// that size.
  static Future<pw.Widget> _textImage(
    List<_Run> runs, {
    double? width,
    required ui.TextDirection direction,
  }) async {
    final paragraph = _paragraph(runs, direction, width ?? 10000);
    final w = width ?? paragraph.maxIntrinsicWidth.ceilToDouble();
    if (width == null) paragraph.layout(ui.ParagraphConstraints(width: w));
    final h = paragraph.height.ceilToDouble();

    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..scale(_scale)
      ..drawParagraph(paragraph, ui.Offset.zero);
    final image = await recorder.endRecording().toImage(
      (w * _scale).ceil(),
      (h * _scale).ceil(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    return pw.Image(
      pw.MemoryImage(png!.buffer.asUint8List()),
      width: w,
      height: h,
    );
  }

  static ui.Paragraph _paragraph(
    List<_Run> runs,
    ui.TextDirection direction,
    double width,
  ) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: direction,
        textAlign: ui.TextAlign.start,
        fontFamily: _family,
      ),
    );
    for (final run in runs) {
      builder
        ..pushStyle(
          ui.TextStyle(
            color: ui.Color(run.color.toInt()),
            fontFamily: _family,
            fontSize: run.size,
            fontWeight: run.bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
            // Room above and below each line for tashkeel, so marks on
            // Quranic text are never clipped by the image edge.
            height: 1.55,
          ),
        )
        ..addText(run.text)
        ..pop();
    }
    return builder.build()..layout(ui.ParagraphConstraints(width: width));
  }

  /// Width Flutter's engine gives [text] — a test hook proving that letters
  /// the pdf package used to drop (e.g. the final ي of "الذي") are drawn.
  @visibleForTesting
  static Future<double> debugTextWidth(String text) async {
    await _ensureFonts();
    return _paragraph(
      [_Run(text, size: 12, color: _ink)],
      ui.TextDirection.rtl,
      10000,
    ).maxIntrinsicWidth;
  }

  static String _fileName(String subjectName, LibraryPdfMode mode) {
    // Keep it readable but filesystem-safe on every platform.
    final safe = subjectName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final now = DateTime.now();
    final stamp = '${now.year}-${_two(now.month)}-${_two(now.day)}';
    final kind = mode == LibraryPdfMode.answerSheet ? '-ورقة-حل' : '';
    return 'مكتبتي-$safe$kind-$stamp.pdf';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static const List<String> _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// e.g. "24 سبتمبر 2026". Written by hand rather than pulling in intl for
  /// one line.
  static String formatArabicDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// One styled stretch of text inside a rendered paragraph.
class _Run {
  final String text;
  final double size;
  final PdfColor color;
  final bool bold;

  const _Run(
    this.text, {
    required this.size,
    required this.color,
    this.bold = false,
  });
}
