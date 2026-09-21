import 'package:flutter/material.dart';

class Course {
  final int id;
  final String name;
  final String academicYear;
  final String madhab;

  /// "1" | "2" for a term course; null for a whole-year course (all of grade 3).
  final String? term;

  /// The student's completion in this course. Null only if the API omitted it.
  final CourseProgress? progress;

  Course({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.madhab,
    this.term,
    this.progress,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    return Course(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? 'all',
      madhab: json['madhab']?.toString() ?? 'all',
      term: json['term']?.toString(),
      progress: progress is Map
          ? CourseProgress.fromJson(Map<String, dynamic>.from(progress))
          : null,
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

/// Completion in one course. [totalLessons] is the curriculum figure for the
/// subject, not how many lessons are uploaded so far ([availableLessons]).
class CourseProgress {
  final int completedLessons;
  final int totalLessons;
  final int availableLessons;
  final double percentage;

  CourseProgress({
    required this.completedLessons,
    required this.totalLessons,
    required this.availableLessons,
    required this.percentage,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    final pct = json['percentage'];
    return CourseProgress(
      completedLessons: toInt(json['completed_lessons']),
      totalLessons: toInt(json['total_lessons']),
      availableLessons: toInt(json['available_lessons']),
      percentage: pct is num ? pct.toDouble() : double.tryParse('$pct') ?? 0,
    );
  }

  double get fraction => (percentage / 100).clamp(0.0, 1.0);
}
