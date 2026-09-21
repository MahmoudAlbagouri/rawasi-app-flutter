// lib/features/stats/data/student_stats.dart
//
// Mirrors GET /api/student/analytics (App\Services\StudentAnalyticsService).
// Totals come from the backend's curriculum config, not from uploaded rows, so
// percentages stay stable as more lessons are published.

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

class StudentStats {
  final Completion completion;
  final List<SubjectProgress> subjects;
  final Streak streak;
  final TimeSpent timeSpent;
  final Pacing pacing;
  final Leaderboard leaderboard;

  StudentStats({
    required this.completion,
    required this.subjects,
    required this.streak,
    required this.timeSpent,
    required this.pacing,
    required this.leaderboard,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      completion: Completion.fromJson(json['completion'] ?? const {}),
      subjects: ((json['subjects'] ?? []) as List)
          .map((e) => SubjectProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      streak: Streak.fromJson(json['streak'] ?? const {}),
      timeSpent: TimeSpent.fromJson(json['time_spent'] ?? const {}),
      pacing: Pacing.fromJson(json['pacing'] ?? const {}),
      leaderboard: Leaderboard.fromJson(json['leaderboard'] ?? const {}),
    );
  }
}

class Completion {
  final int completedLessons;
  final int totalLessons;
  final int remainingLessons;
  final double percentage;

  Completion({
    required this.completedLessons,
    required this.totalLessons,
    required this.remainingLessons,
    required this.percentage,
  });

  factory Completion.fromJson(Map<String, dynamic> json) => Completion(
        completedLessons: _int(json['completed_lessons']),
        totalLessons: _int(json['total_lessons']),
        remainingLessons: _int(json['remaining_lessons']),
        percentage: _num(json['percentage']),
      );
}

class SubjectProgress {
  final String key;
  final String label;

  /// 'lesson' or 'warad' — the Quran track is counted in أوراد.
  final String unit;
  final int completedLessons;
  final int totalLessons;
  final int remainingLessons;

  /// How much of this subject is uploaded so far, which can be far below the
  /// curriculum total while content is still being added.
  final int availableLessons;
  final double percentage;

  SubjectProgress({
    required this.key,
    required this.label,
    required this.unit,
    required this.completedLessons,
    required this.totalLessons,
    required this.remainingLessons,
    required this.availableLessons,
    required this.percentage,
  });

  String get unitLabel => unit == 'warad' ? 'ورد' : 'درس';

  factory SubjectProgress.fromJson(Map<String, dynamic> json) => SubjectProgress(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        unit: json['unit']?.toString() ?? 'lesson',
        completedLessons: _int(json['completed_lessons']),
        totalLessons: _int(json['total_lessons']),
        remainingLessons: _int(json['remaining_lessons']),
        availableLessons: _int(json['available_lessons']),
        percentage: _num(json['percentage']),
      );
}

class Streak {
  final int current;
  final int longest;

  Streak({required this.current, required this.longest});

  factory Streak.fromJson(Map<String, dynamic> json) => Streak(
        current: _int(json['current']),
        longest: _int(json['longest']),
      );
}

class TimeSpent {
  final int seconds;
  final int minutes;
  final double hours;

  TimeSpent({required this.seconds, required this.minutes, required this.hours});

  factory TimeSpent.fromJson(Map<String, dynamic> json) => TimeSpent(
        seconds: _int(json['seconds']),
        minutes: _int(json['minutes']),
        hours: _num(json['hours']),
      );

  /// "2 ساعة و 2 دقيقة" — falls back to minutes, then seconds, for short runs.
  String get label {
    if (seconds <= 0) return 'لم تبدأ بعد';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return m > 0 ? '$h ساعة و $m دقيقة' : '$h ساعة';
    if (m > 0) return '$m دقيقة';
    return '$seconds ثانية';
  }
}

class Pacing {
  final double lessonsPerWeek;
  final int remainingLessons;
  final String? estimatedCompletionDate;

  Pacing({
    required this.lessonsPerWeek,
    required this.remainingLessons,
    this.estimatedCompletionDate,
  });

  factory Pacing.fromJson(Map<String, dynamic> json) => Pacing(
        lessonsPerWeek: _num(json['lessons_per_week']),
        remainingLessons: _int(json['remaining_lessons']),
        estimatedCompletionDate: json['estimated_completion_date']?.toString(),
      );
}

class Leaderboard {
  final List<LeaderboardEntry> top;
  final int? myRank;
  final int myPoints;

  /// The cohort this board ranks: the student's academic year and, for the
  /// termed grades, their term. Grade 3 has no terms, so [scopeTerm] is null.
  final String scopeYear;
  final String? scopeTerm;

  Leaderboard({
    required this.top,
    this.myRank,
    required this.myPoints,
    required this.scopeYear,
    this.scopeTerm,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final me = Map<String, dynamic>.from(json['me'] as Map? ?? const {});
    final scope = Map<String, dynamic>.from(json['scope'] as Map? ?? const {});
    return Leaderboard(
      top: ((json['top'] ?? []) as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: me['rank'] == null ? null : _int(me['rank']),
      myPoints: _int(me['points']),
      scopeYear: scope['academic_year']?.toString() ?? '',
      scopeTerm: scope['term']?.toString(),
    );
  }

  /// "الصف الأول الثانوي — الفصل الأول"
  String get scopeLabel {
    final year = switch (scopeYear) {
      '1' => 'الصف الأول الثانوي',
      '2' => 'الصف الثاني الثانوي',
      '3' => 'الصف الثالث الثانوي',
      _ => 'صفّك الدراسي',
    };
    final term = switch (scopeTerm) {
      '1' => ' — الفصل الأول',
      '2' => ' — الفصل الثاني',
      _ => '',
    };
    return '$year$term';
  }
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final int completedLessons;
  final bool isCurrentStudent;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.completedLessons,
    required this.isCurrentStudent,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: _int(json['rank']),
        name: json['name']?.toString() ?? 'طالب',
        points: _int(json['points']),
        completedLessons: _int(json['completed_lessons']),
        isCurrentStudent: json['is_current_student'] == true,
      );
}
