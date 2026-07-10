class LibraryItem {
  final int id;
  final String type;
  final String taskTitle;
  final Libraryable libraryable;
  final String course;
  final String createdAt;

  LibraryItem({
    required this.id,
    required this.type,
    required this.taskTitle,
    required this.libraryable,
    required this.course,
    required this.createdAt,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'],
      type: json['type'],
      taskTitle: json['task_title'] ?? '',
      libraryable: Libraryable.fromJson(json['libraryable']),
      course: json['course'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Libraryable {
  final int id;
  final String? type; // للأسئلة
  final String? question; // للأسئلة
  final String? correctAnswer; // للأسئلة

  final String? title; // للفيديوهات
  final String? video; // للفيديوهات
  final String? description; // للفيديوهات
  final int? dayNumber;
  final int? courseId;
  final String? createdAt;
  final String? updatedAt;

  Libraryable({
    required this.id,
    this.type,
    this.question,
    this.correctAnswer,
    this.title,
    this.video,
    this.description,
    this.dayNumber,
    this.courseId,
    this.createdAt,
    this.updatedAt,
  });

  factory Libraryable.fromJson(Map<String, dynamic> json) {
    return Libraryable(
      id: json['id'],
      type: json['type'],
      question: json['question'],
      correctAnswer: json['correct_answer'],
      title: json['title'],
      video: json['video']?.toString().trim(),
      description: json['description'],
      dayNumber: json['day_number'],
      courseId: json['course_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
