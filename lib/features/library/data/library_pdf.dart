// lib/features/library/data/library_pdf.dart
//
// "استخراج PDF" for one library subject.
//
// Generated CLIENT-SIDE. The questions are already in memory once the subject
// has been opened, so this needs no new endpoint, no auth on a binary response
// and no download handling — and it works with no connection. The one real
// cost of the client-side route is Arabic: the pdf package ships no Arabic
// glyphs, so without an explicitly loaded TTF every letter renders as a box.
// The app already bundles Tajawal for its own UI, so that same font is reused
// and nothing new was added to the asset list beyond exposing assets/fonts/ to
// rootBundle.
//
// Layout is wrapped in a pw.Directionality(rtl) and the theme carries the
// Arabic font for both regular and bold, so headings, numbering and body text
// all lay out right-to-left.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';

/// Brand colour, kept in step with AppColors.brandPrimary (#135E8D).
const PdfColor _brand = PdfColor.fromInt(0xFF135E8D);
const PdfColor _ink = PdfColor.fromInt(0xFF1F2937);
const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
const PdfColor _tint = PdfColor.fromInt(0xFFF1F6FA);

class LibraryPdf {
  /// Thrown rather than producing a document with no questions in it.
  static const String emptyMessage = 'لا توجد أسئلة محفوظة في هذه المادة.';

  /// Builds the PDF and opens the system share/save sheet.
  ///
  /// Returns false if the student dismissed the sheet without saving or
  /// sharing, so the caller can stay quiet instead of claiming success.
  static Future<bool> shareSubject({
    required String subjectName,
    required List<ContentItem> questions,
  }) async {
    if (questions.isEmpty) {
      throw StateError(emptyMessage);
    }

    final bytes = await build(subjectName: subjectName, questions: questions);

    return Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(subjectName),
    );
  }

  /// The document itself, split out so it can be built and inspected without
  /// touching the platform share sheet.
  ///
  /// [direction] exists only so a test can build the same document LTR and
  /// prove the RTL output really differs - i.e. that the pdf package applied
  /// Arabic shaping (`arabic.convert`, which it only runs when the resolved
  /// text direction is RTL) rather than laying the letters out disconnected
  /// and backwards. Production always uses the default.
  static Future<Uint8List> build({
    required String subjectName,
    required List<ContentItem> questions,
    @visibleForTesting pw.TextDirection direction = pw.TextDirection.rtl,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'),
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final exportedOn = formatArabicDate(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        // Installs an InheritedDirectionality for the whole page. This is
        // what makes the pdf package shape Arabic: it only calls
        // arabic.convert when the resolved direction is RTL, so without this
        // the glyphs come out unjoined and in the wrong order.
        textDirection: direction,
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  subjectName,
                  style: pw.TextStyle(fontSize: 10, color: _muted),
                ),
              ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
        build: (context) => [
          _title(subjectName, questions.length, exportedOn),
          pw.SizedBox(height: 18),
          for (var i = 0; i < questions.length; i++)
            _questionBlock(i + 1, questions[i]),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _title(String subjectName, int count, String exportedOn) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _tint,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _brand, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'أسئلتي المحفوظة',
            style: pw.TextStyle(fontSize: 12, color: _muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subjectName,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _brand,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'عدد الأسئلة: $count   •   تاريخ الاستخراج: $exportedOn',
            style: pw.TextStyle(fontSize: 11, color: _ink),
          ),
        ],
      ),
    );
  }

  static pw.Widget _questionBlock(int number, ContentItem item) {
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
                decoration: pw.BoxDecoration(
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
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.libraryable.typeLabel,
                      style: pw.TextStyle(fontSize: 9, color: _brand),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      item.questionText,
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _tint,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'الإجابة',
                  style: pw.TextStyle(fontSize: 9, color: _muted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  item.answerText.isEmpty ? 'غير متوفرة' : item.answerText,
                  style: pw.TextStyle(fontSize: 12, color: _ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fileName(String subjectName) {
    // Keep it readable but filesystem-safe on every platform.
    final safe = subjectName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final now = DateTime.now();
    final stamp = '${now.year}-${_two(now.month)}-${_two(now.day)}';
    return 'مكتبتي-$safe-$stamp.pdf';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static const List<String> _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  /// e.g. "24 سبتمبر 2026". Written by hand rather than pulling in intl for
  /// one line.
  static String formatArabicDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
