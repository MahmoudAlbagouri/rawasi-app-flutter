import 'package:flutter/material.dart';

class Course {
  final int id;
  final String name;
  final String academicYear;
  final String madhab;

  /// "1" | "2" for a term course; null for a whole-year course (all of grade 3).
  final String? term;

  Course({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.madhab,
    this.term,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? 'all',
      madhab: json['madhab']?.toString() ?? 'all',
      term: json['term']?.toString(),
    );
  }

  /// A subject-specific icon, keyed off the same course names the backend's
  /// config/curriculum.php `match` arrays use. Unknown subjects fall back to
  /// the generic book.
  IconData get icon {
    final n = _normalized(name);

    if (n.contains('قران')) return Icons.auto_stories; // القرآن الكريم — mushaf
    if (n.contains('فقه')) return Icons.balance; // الفقه الحنفي / الشافعي — scales
    if (n.contains('تفسير')) return Icons.manage_search; // التفسير — text under a magnifier
    if (n.contains('حديث')) return Icons.format_quote; // الحديث — quotation
    if (n.contains('توحيد')) return Icons.star; // التوحيد
    if (n.contains('ميراث') || n.contains('مواريث')) return Icons.account_tree; // الميراث — family tree

    return Icons.menu_book;
  }

  /// Strips Arabic diacritics and hamza variants and collapses whitespace, so
  /// "القُرْآن  الكَريم" and "القرآن الكريم" resolve to the same icon.
  static String _normalized(String value) {
    final stripped = value
        .replaceAll(RegExp(r'[ً-ْٰـ]'), '') // tashkeel + tatweel
        .replaceAll(RegExp(r'[آأإ]'), 'ا') // آ أ إ → ا
        .replaceAll('ة', 'ه') // ة → ه
        .replaceAll('ى', 'ي'); // ى → ي
    return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
