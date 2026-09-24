// lib/features/stats/data/student_stats.dart
//
// Mirrors GET /api/student/analytics (App\Services\StudentAnalyticsService).
// Totals come from the backend's curriculum config, not from uploaded rows, so
// percentages stay stable as more lessons are published.

import 'package:rawasi_app_n/shared/arabic_plural.dart';

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
  final Inactivity inactivity;

  StudentStats({
    required this.completion,
    required this.subjects,
    required this.streak,
    required this.timeSpent,
    required this.pacing,
    required this.leaderboard,
    required this.inactivity,
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
      // Added after the other keys, so an older payload without it still
      // parses - the card then renders its "never started" state.
      inactivity: Inactivity.fromJson(json['inactivity'] ?? const {}),
    );
  }
}

/// Days since the student last studied a new lesson.
///
/// Comes from the same activity() the dashboard student table reads, so the
/// figure a student sees and the one an admin sees cannot drift apart.
///
/// [delayDays] is null when there is nothing to measure from at all: no
/// completed question and no activation date.
class Inactivity {
  final String? lastStudyDate;
  final int? delayDays;

  Inactivity({this.lastStudyDate, this.delayDays});

  factory Inactivity.fromJson(Map<String, dynamic> json) => Inactivity(
        lastStudyDate: json['last_study_date']?.toString(),
        delayDays: json['delay_days'] == null ? null : _int(json['delay_days']),
      );

  bool get hasStarted => delayDays != null;

  /// The headline. Deliberately a nudge, not a scolding.
  String get label {
    final days = delayDays;
    if (days == null) return 'لم تبدأ بعد';
    if (days == 0) return 'درست اليوم';
    return 'مر ${arabicDays(days)} منذ آخر درس';
  }

  /// The supporting line under [label].
  ///
  /// At three days the next lesson unlocks by itself (the 3-day auto-unlock
  /// rule), so past that point the honest message is "it is already open",
  /// not "you are behind". The rule itself is untouched — this only describes
  /// it.
  String get hint {
    final days = delayDays;
    if (days == null) return 'ابدأ أول درس لتبدأ المتابعة';
    if (days == 0) return 'واصل التقدم';
    if (days < 3) return 'عُد لإكمال ما بدأته';
    return 'الدرس التالي مفتوح لك الآن';
  }
}

class Completion {
  final int completedLessons;
  final int totalLessons;
  final int remainingLessons;

  /// Completed lessons against the grade's FULL curriculum total
  /// (config/curriculum.php), not against however many lessons are uploaded.
  final double percentage;

  Completion({
    required this.completedLessons,
    required this.totalLessons,
    required this.remainingLessons,
    required this.percentage,
  });

  /// "40" / "2.9" — the single formatter for this figure.
  ///
  /// Home and إحصائياتي both render this, so the two screens cannot print the
  /// same number to different precision. (Home used to show
  /// `Student.progress` instead, which is a different statistic entirely:
  /// completed QUESTIONS over every question in the database, unscoped by
  /// grade or madhab. See the note in home_view.dart.)
  String get percentLabel =>
      percentage == percentage.roundToDouble()
          ? percentage.toInt().toString()
          : percentage.toString();

  /// 0.0–1.0, for progress indicators.
  double get fraction => (percentage / 100).clamp(0.0, 1.0);

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

  /// Already in the payload; needed to tell a real weekly average from a
  /// first-day burst, where the rate outruns the work actually done.
  final int completedLessons;

  final String? estimatedCompletionDate;

  Pacing({
    required this.lessonsPerWeek,
    required this.remainingLessons,
    this.completedLessons = 0,
    this.estimatedCompletionDate,
  });

  factory Pacing.fromJson(Map<String, dynamic> json) => Pacing(
        lessonsPerWeek: _num(json['lessons_per_week']),
        remainingLessons: _int(json['remaining_lessons']),
        completedLessons: _int(json['completed_lessons']),
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
