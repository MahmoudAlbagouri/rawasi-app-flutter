class LessonItem {
  final int id;
  final String title;
  final String type; // "Question" أو "Video"

  LessonItem({required this.id, required this.title, required this.type});

  factory LessonItem.fromJson(Map<String, dynamic> json) {
    return LessonItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'بدون عنوان',
      type:
          (json['type'] as String?)?.trim().toLowerCase().capitalize() ??
          'Question',
    );
  }
}

// مساعدة: لتحويل "question" → "Question"
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
