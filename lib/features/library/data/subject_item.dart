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

  /// The most questions this student may keep in this subject, from
  /// config/library.php server-side. Null when the API did not send it.
  ///
  /// Carried so the library can show "95 / 100" and warn BEFORE the student
  /// tries to save a 101st question. The server enforces the cap either way —
  /// this only decides whether the student finds out by being told or by being
  /// refused.
  final int? maxSavedQuestions;

  SubjectItem({
    required this.id,
    required this.name,
    this.savedQuestionsCount = 0,
    this.maxSavedQuestions,
  });

  factory SubjectItem.fromJson(Map<String, dynamic> json) {
    return SubjectItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      savedQuestionsCount: _int(json['saved_questions_count']),
      // Nullable on purpose: _int would turn a missing cap into 0, and 0 would
      // read as "nothing may be saved" — the opposite of "no cap known".
      maxSavedQuestions: json['max_saved_questions'] == null
          ? null
          : _int(json['max_saved_questions']),
    );
  }

  /// True once this subject's library is full.
  ///
  /// Read from the counts rather than the API's `is_full`, so it stays right
  /// after a local [copyWith] — removing a question updates the count here
  /// without a round trip, and a stale flag would still say "full".
  bool get isFull =>
      maxSavedQuestions != null && savedQuestionsCount >= maxSavedQuestions!;

  /// How many more fit, or null when no cap is known.
  int? get remainingSlots => maxSavedQuestions == null
      ? null
      : (maxSavedQuestions! - savedQuestionsCount).clamp(0, maxSavedQuestions!);

  /// The API has returned counts as both int and string in other endpoints;
  /// parse defensively rather than crash the whole library list.
  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  SubjectItem copyWith({int? savedQuestionsCount, int? maxSavedQuestions}) =>
      SubjectItem(
        id: id,
        name: name,
        savedQuestionsCount: savedQuestionsCount ?? this.savedQuestionsCount,
        maxSavedQuestions: maxSavedQuestions ?? this.maxSavedQuestions,
      );
}
