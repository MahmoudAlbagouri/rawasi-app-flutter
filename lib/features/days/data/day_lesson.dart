// lib/features/days/models/day_lesson.dart

enum LessonStatus {
  completed, // dayNumber < currentDay → تم إنجازه
  current, // dayNumber == currentDay → اليوم الحالي (مفتوح)
  locked, // dayNumber > currentDay → مقفول (منطقيًا)
}

class DayLesson {
  final int id;
  final int dayNumber; // ← تم تغيير النوع إلى int
  final String title;
  final int currentDay;
  final int expectedCurrentDay; // ← يُستخدم لحساب "تأخر المستخدم"

  DayLesson({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.currentDay,
    required this.expectedCurrentDay,
  });

  // الحالة الأساسية (كما طلبت)
  LessonStatus get status {
    if (dayNumber < currentDay) {
      return LessonStatus.completed;
    } else if (dayNumber == currentDay) {
      return LessonStatus.current;
    } else {
      return LessonStatus.locked;
    }
  }

  /// ✅ هل هذا الدرس متأخر؟ (يظهر العلامة من اليوم التالي لـ currentDay حتى expectedCurrentDay)
  bool get isOverdueLesson {
    // يظهر العلامة فقط إذا كان المستخدم متأخرًا (expected > current)
    // والدرس ضمن النطاق: currentDay < dayNumber <= expectedCurrentDay
    return expectedCurrentDay > currentDay &&
        dayNumber > currentDay &&
        dayNumber <= expectedCurrentDay;
  }

  /// ✅ هل الدرس مقفول بسبب التقدم السريع؟
  /// (حتى لو dayNumber <= currentDay، لكنه > expectedCurrentDay)
  bool get isLockedBySchedule {
    return dayNumber > expectedCurrentDay;
  }

  /// ✅ هل يمكن النقر على الدرس؟
  bool get isTappable {
    return !isLockedBySchedule && status != LessonStatus.locked;
  }

  /// ✅ رسالة عند محاولة فتح يوم مقفول بسبب الجدول
  String get lockMessage {
    if (isLockedBySchedule) {
      return 'سيتم فتح اليوم غدًا';
    } else if (status == LessonStatus.locked) {
      return 'اليوم غير متوفر بعد';
    }
    return '';
  }

  factory DayLesson.fromJson(
    Map<String, dynamic> json, {
    required int currentDay,
    required int expectedCurrentDay,
  }) {
    // التعامل مع الحالة التي يُرسل فيها day_number كـ String من API
    final rawDayNumber = json['day_number'];
    int parsedDayNumber;
    if (rawDayNumber is int) {
      parsedDayNumber = rawDayNumber;
    } else if (rawDayNumber is String) {
      parsedDayNumber = int.tryParse(rawDayNumber) ?? 0;
    } else {
      parsedDayNumber = 0;
    }

    return DayLesson(
      id: json['id'] as int? ?? 0,
      dayNumber: parsedDayNumber, // ← الآن int
      title: json['title'] as String? ?? 'غير معروف',
      currentDay: currentDay,
      expectedCurrentDay: expectedCurrentDay,
    );
  }
}
