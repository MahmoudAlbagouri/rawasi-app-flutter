// lib/features/lessons/data/lesson_dayable_model.dart

class LessonDayableVideo {
  final int dailyTaskId; // ✅ id من الجذر (مثل: 13)

  final int videoId; // ← id من الجذر (مثلاً: { "id": 2, ... }) → هذا هو task_id
  final int id; // ← id من dayable
  final String title;
  final String video;
  final int dayNumber;
  final String description;
  final String type;
  final bool isCompleted;
  final List<Attach>? attaches;
  final int courseId; // ← من الاستجابة (course_id)

  LessonDayableVideo({
    required this.dailyTaskId,

    required this.videoId,
    required this.id,
    required this.title,
    required this.video,
    required this.dayNumber,
    required this.description,
    required this.type,
    required this.isCompleted,
    this.attaches,
    required this.courseId,
  });

  factory LessonDayableVideo.fromJson(Map<String, dynamic> json) {
    final dayableJson = json['dayable'] as Map<String, dynamic>?;

    if (dayableJson == null) {
      throw Exception('بيانات الدرس غير صالحة: الحقل "dayable" مفقود');
    }

    String _safeString(dynamic value, String fallback) {
      if (value == null) return fallback;
      if (value is String) return value.trim();
      return value.toString().trim();
    }

    final attachesJson = dayableJson['attaches'];
    List<Attach>? attachesList;
    if (attachesJson is List) {
      attachesList = attachesJson
          .map(
            (item) => item is Map<String, dynamic>
                ? Attach.fromJson(item)
                : Attach.empty(),
          )
          .toList();
    } else {
      attachesList = null;
    }

    // final courseId = int.tryParse(_safeString(json['course_id'], '0')) ?? 0;

    return LessonDayableVideo(
      dailyTaskId: json['id'] as int? ?? 0, // ✅ من الجذر

      videoId: dayableJson['video_id'] as int? ?? 0,
      id: dayableJson['id'] as int? ?? 0,
      title: _safeString(dayableJson['title'], 'بدون عنوان'),
      video: _safeString(dayableJson['video'], ''),
      dayNumber: dayableJson['day_number'] as int? ?? 0,
      description: _safeString(dayableJson['description'], 'لا يوجد وصف'),
      type: _safeString(dayableJson['type'], 'unknown').toLowerCase(),
      isCompleted: dayableJson['is_completed'] as bool? ?? false,
      attaches: attachesList,
      courseId: dayableJson['course_id'] as int? ?? 0,
    );
  }
}

class Attach {
  final int id;
  final String attach;
  final String fullPathAttach;

  Attach({
    required this.id,
    required this.attach,
    required this.fullPathAttach,
  });

  factory Attach.empty() {
    return Attach(id: 0, attach: '', fullPathAttach: '');
  }

  factory Attach.fromJson(Map<String, dynamic> json) {
    String _safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      return value.toString().trim();
    }

    return Attach(
      id: json['id'] as int? ?? 0,
      attach: _safeString(json['attach']),
      fullPathAttach: _safeString(json['full_path_attach']),
    );
  }

  String get fileName {
    final parts = attach.split('/');
    return parts.isEmpty ? attach : parts.last;
  }
}
