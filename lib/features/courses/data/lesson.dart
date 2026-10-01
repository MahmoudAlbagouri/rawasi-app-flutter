class Lesson {
  final int id;
  final int courseId;
  final String title;
  final int order;
  final String status; // locked | unlocked | completed
  final bool isUnlocked;
  final bool isCompleted;
  final int questionsCount;
  final int completedQuestionsCount;
  final String? unlockedAt;

  /// True when SUBSCRIBING is what would open this lesson — the free-plan
  /// allowance is the only thing in the way.
  ///
  /// Deliberately narrower than "locked and past the allowance": the backend
  /// only sets it when the previous lesson is already complete, so paying
  /// really would open this one. A lesson held by both the paywall and the
  /// sequence arrives as an ordinary lock, because telling the student to pay
  /// would not open what they just tapped.
  final bool requiresPayment;

  /// How many of this course's lessons the free plan reaches, or null when the
  /// student is not capped.
  final int? freeLimitLessons;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.status,
    required this.isUnlocked,
    required this.isCompleted,
    required this.questionsCount,
    required this.completedQuestionsCount,
    this.unlockedAt,
    this.requiresPayment = false,
    this.freeLimitLessons,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as int? ?? 0,
      courseId: json['course_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      status: json['status'] as String? ?? 'locked',
      isUnlocked: json['is_unlocked'] == true,
      isCompleted: json['is_completed'] == true,
      questionsCount: json['questions_count'] as int? ?? 0,
      completedQuestionsCount: json['completed_questions_count'] as int? ?? 0,
      unlockedAt: json['unlocked_at'] as String?,
      requiresPayment: json['requires_payment'] == true,
      freeLimitLessons: json['free_limit_lessons'] as int?,
    );
  }

  /// When the next lesson auto-unlocks if this one is not completed in time.
  DateTime? get autoUnlockDeadline {
    if (unlockedAt == null) return null;
    final parsed = DateTime.tryParse(unlockedAt!);
    return parsed?.add(const Duration(days: 3));
  }
}
