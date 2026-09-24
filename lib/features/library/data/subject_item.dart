// lib/features/library/data/subject_item.dart

/// A subject in the student's library, as LibrarySubjectResource returns it.
class SubjectItem {
  final int id;
  final String name;

  /// How many questions **this** student has saved in this subject.
  ///
  /// Server-side `withCount` constrained to the authenticated student, so it
  /// is never a global total. Drives the card badge, the summary's "remaining"
  /// figure, and whether the PDF export button is enabled.
  final int savedQuestionsCount;

  SubjectItem({
    required this.id,
    required this.name,
    this.savedQuestionsCount = 0,
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      savedQuestionsCount: _int(json['saved_questions_count']),
    );
  }

  /// The API has returned counts as both int and string in other endpoints;
  /// parse defensively rather than crash the whole library list.
  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  SubjectItem copyWith({int? savedQuestionsCount}) => SubjectItem(
        id: id,
        name: name,
        savedQuestionsCount: savedQuestionsCount ?? this.savedQuestionsCount,
      );
}
