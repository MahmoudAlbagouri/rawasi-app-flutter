// lib/features/library/data/content_item.dart

class ContentItem {
  final int id;
  final String type; // 'Question' أو 'Video'
  final String taskTitle;
  final ContentDetail libraryable;
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
      libraryable: ContentDetail.fromJson(json['libraryable']),
      course: json['course'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ContentDetail {
  final int id;
  // للأسئلة
  final String? question;
  final String? correctAnswer;
  // للفيديوهات
  final String? title;
  final String? video;
  final String? description;

  ContentDetail({
    required this.id,
    this.question,
    this.correctAnswer,
    this.title,
    this.video,
    this.description,
  });

  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    return ContentDetail(
      id: json['id'] ?? 0,
      question: json['question'],
      correctAnswer: json['correct_answer'],
      title: json['title'],
      video: json['video']?.toString().trim(),
      description: json['description'],
    );
  }
}
