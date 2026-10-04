// lib/features/courses/data/subject_group.dart
//
// Collapses the per-term course rows into one card per subject.
//
// WHY THIS EXISTS: since term stopped being a visibility axis, a grade-1 or
// grade-2 student is returned BOTH terms of every subject — 5 subjects × 2
// terms = 10 rows. Rendered raw that reads as duplicated content: "التفسير"
// twice, "التوحيد" twice, and so on, with no visible difference between them.
//
// THE TRAP IN MERGING THEM: each term row reports the SUBJECT's full
// curriculum total, not that term's share — التفسير|1 and التفسير|2 both say
// 39. Summing the totals would show 78 and halve every percentage. So:
//
//   completed  → summed   (each course owns its own lessons, no overlap)
//   available  → summed   (same reason)
//   total      → SHARED   (already the whole-subject figure; taking it once)
//
// Both the courses screen and the home grid group through this one function,
// so they cannot disagree about what a subject's progress is.

import 'package:flutter/widgets.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';

class SubjectGroup {
  final String name;
  final IconData icon;

  /// The term rows this card stands for, in term order.
  final List<Course> courses;

  /// Where a tap goes: the first term still unfinished, else the first.
  ///
  /// With two terms visible that lands the student on the one they are
  /// actually working through rather than always sending them back to term 1.
  final Course target;

  final int completedLessons;
  final int totalLessons;
  final int availableLessons;

  const SubjectGroup({
    required this.name,
    required this.icon,
    required this.courses,
    required this.target,
    required this.completedLessons,
    required this.totalLessons,
    required this.availableLessons,
  });

  /// False when no term carried progress figures, so callers can render the
  /// card without inventing numbers.
  bool get hasProgress => totalLessons > 0;

  double get percentage =>
      totalLessons == 0 ? 0 : (completedLessons / totalLessons) * 100;

  double get fraction => (percentage / 100).clamp(0.0, 1.0);

  /// "5 من 39", or null when there is nothing to report.
  String? get countLabel =>
      hasProgress ? '$completedLessons من $totalLessons' : null;
}

/// One entry per subject, ordered by name.
List<SubjectGroup> groupCoursesBySubject(List<Course> courses) {
  final byName = <String, List<Course>>{};

  for (final course in courses) {
    byName.putIfAbsent(course.name.trim(), () => []).add(course);
  }

  final groups = <SubjectGroup>[];

  byName.forEach((name, group) {
    // Stable order, so "first unfinished" means the earliest term.
    group.sort((a, b) => (a.term ?? '').compareTo(b.term ?? ''));

    var completed = 0;
    var available = 0;
    var total = 0;

    for (final course in group) {
      final p = course.progress;
      if (p == null) continue;

      completed += p.completedLessons;
      available += p.availableLessons;
      // NOT summed: every term already reports the whole-subject total.
      if (p.totalLessons > total) total = p.totalLessons;
    }

    groups.add(
      SubjectGroup(
        name: name,
        icon: group.first.icon,
        courses: group,
        target: group.firstWhere(
          (c) => (c.progress?.percentage ?? 0) < 100,
          orElse: () => group.first,
        ),
        completedLessons: completed,
        totalLessons: total,
        availableLessons: available,
      ),
    );
  });

  groups.sort((a, b) => a.name.compareTo(b.name));

  return groups;
}
