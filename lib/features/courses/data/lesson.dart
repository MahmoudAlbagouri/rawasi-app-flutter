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
  /// student is not capped. Measured against the course's fixed curriculum
  /// total, rounded down — never more than 25% of it.
  final int? freeLimitLessons;

  /// Which free-plan limit is in the way when [requiresPayment]:
  /// 'free_limit' (the 25% content cap) or 'trial_ended' (the 15-day free
  /// period). Null otherwise, and on older backends.
  final String? paywallReason;

  static const String paywallFreeLimit = 'free_limit';
  static const String paywallTrialEnded = 'trial_ended';

  bool get isTrialEndedPaywall => paywallReason == paywallTrialEnded;

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
    this.paywallReason,
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
      paywallReason: json['paywall_reason'] as String?,
    );
  }

  // There is no autoUnlockDeadline any more. Lessons used to open on their own
  // 3 days after the one before them, which is what made finishing a lesson
  // appear to open two; the backend dropped that rule on 2026-10-09, so there
  // is no deadline to show. `unlockedAt` is still sent and still means "when
  // this lesson became available".
}
