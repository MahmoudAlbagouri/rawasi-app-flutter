// lib/features/library/data/content_item.dart

import 'package:rawasi_app_n/features/courses/data/question.dart'
    show questionTypeLabel;

/// One saved row in the student's library, as LibraryResource returns it.
class ContentItem {
  /// The LIBRARY row id — this is what DELETE /remove-from-library/{id} takes,
  /// not the question id.
  final int id;

  /// The library row's own type, always `question`. The *question's* type
  /// (multiple_choice, definitions, …) is [ContentDetail.type].
  final String type;

  /// The question text. Was always '' until LibraryResource stopped reading a
  /// `title` column that Questions do not have.
  final String taskTitle;

  final ContentDetail libraryable;

  /// Course name. Was always '' too — the resource read a misspelled relation.
  final String course;

  final String createdAt;

  ContentItem({
    required this.id,
    required this.type,
    required this.taskTitle,
    required this.libraryable,
    required this.course,
    required this.createdAt,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      taskTitle: json['task_title'] ?? '',
      libraryable: ContentDetail.fromJson(json['libraryable'] ?? const {}),
      course: json['course'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  /// Prefers the nested payload and falls back to the flattened field, so a
  /// row still renders if one side of the response is missing.
  String get questionText =>
      (libraryable.question?.isNotEmpty ?? false) ? libraryable.question! : taskTitle;

  String get answerText => libraryable.correctAnswer ?? '';
}

/// The saved Question itself.
///
/// The video fields (`title`, `video`, `description`) are gone: that engine is
/// retired per CLAUDE.md, the library has only ever held questions, and the
/// commented-out `type = 'video'` branch it went with has been removed from
/// LibraryController too.
class ContentDetail {
  final int id;
  final String? question;
  final String? correctAnswer;

  /// The backend QuestionType value, e.g. `definitions`.
  final String? type;

  ContentDetail({
    required this.id,
    this.question,
    this.correctAnswer,
    this.type,
  });

  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    return ContentDetail(
      id: json['id'] ?? 0,
      question: json['question'],
      correctAnswer: json['correct_answer'],
      type: json['type'],
    );
  }

  /// Arabic label for the picker/badge — never the raw enum value.
  String get typeLabel => questionTypeLabel(type);
}
