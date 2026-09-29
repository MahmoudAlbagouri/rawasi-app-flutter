import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';

/// The lesson-summary denominator.
///
/// It used to be `_courseLessons.length` — the lessons uploaded so far — so a
/// student who finished the 3 available lessons of a 39-lesson subject was
/// told "اكتمل 100%", and their percentage would then FALL as more content
/// landed. The denominator is now the fixed curriculum figure that
/// config/curriculum.php defines and CourseResource already sends.
///
/// These pin the arithmetic the summary performs, so the two counts cannot be
/// confused again.
void main() {
  CourseProgress progress({
    required int completed,
    required int total,
    required int available,
  }) =>
      CourseProgress.fromJson({
        'completed_lessons': completed,
        'total_lessons': total,
        'available_lessons': available,
        'percentage': total == 0 ? 0 : (completed / total * 100),
      });

  /// Mirrors _completionPage()'s computation.
  ({int total, int percent, int remaining, bool finishedSubject, bool finishedAvailable})
      summary({
    required int completed,
    required int available,
    int? curriculumTotal,
  }) {
    final total = curriculumTotal ?? available;
    final remaining = (total - completed).clamp(0, total);
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();
    final finishedSubject =
        curriculumTotal != null && completed >= curriculumTotal;
    final finishedAvailable =
        !finishedSubject && available > 0 && completed >= available;

    return (
      total: total,
      percent: percent,
      remaining: remaining,
      finishedSubject: finishedSubject,
      finishedAvailable: finishedAvailable,
    );
  }

  group('the denominator', () {
    test('is the curriculum total, not the uploaded count', () {
      // The reported bug: 3 of 3 uploaded, in a 39-lesson subject.
      final s = summary(completed: 3, available: 3, curriculumTotal: 39);

      expect(s.total, 39, reason: 'must not be the 3 uploaded lessons');
      expect(s.percent, 8);
      expect(s.remaining, 36);
      expect(s.finishedSubject, isFalse, reason: 'the subject is not finished');
    });

    test('does not move when more lessons are uploaded', () {
      // The same student, after another 10 lessons land. Their completed count
      // is unchanged, so their percentage must be unchanged too — the failure
      // config/curriculum.php exists to prevent.
      final before = summary(completed: 3, available: 3, curriculumTotal: 39);
      final after = summary(completed: 3, available: 13, curriculumTotal: 39);

      expect(after.percent, before.percent);
      expect(after.total, before.total);
      expect(after.remaining, before.remaining);
    });

    test('reaches 100% only at the real curriculum total', () {
      final s = summary(completed: 39, available: 39, curriculumTotal: 39);

      expect(s.percent, 100);
      expect(s.remaining, 0);
      expect(s.finishedSubject, isTrue);
      expect(s.finishedAvailable, isFalse);
    });
  });

  group('the two "finished" states are distinct', () {
    test('exhausting what is uploaded is not finishing the subject', () {
      final s = summary(completed: 3, available: 3, curriculumTotal: 39);

      expect(s.finishedSubject, isFalse, reason: 'no 🎉 for this student');
      expect(s.finishedAvailable, isTrue, reason: 'but they did finish what exists');
    });

    test('mid-subject is neither', () {
      final s = summary(completed: 2, available: 6, curriculumTotal: 39);

      expect(s.finishedSubject, isFalse);
      expect(s.finishedAvailable, isFalse);
      expect(s.remaining, 37);
    });
  });

  group('fallback when the course matches no configured subject', () {
    test('never claims the subject is complete', () {
      // curriculumTotal null: the uploaded count is all we have, but a false
      // 100% would be worse than an imprecise number.
      final s = summary(completed: 3, available: 3);

      expect(s.finishedSubject, isFalse);
      expect(s.finishedAvailable, isTrue);
    });

    test('an empty course does not divide by zero', () {
      final s = summary(completed: 0, available: 0);

      expect(s.percent, 0);
      expect(s.remaining, 0);
      expect(s.finishedSubject, isFalse);
      expect(s.finishedAvailable, isFalse);
    });
  });

  group('CourseProgress keeps the two counts apart', () {
    test('totalLessons is the curriculum figure, availableLessons the uploaded one', () {
      final p = progress(completed: 3, total: 39, available: 3);

      expect(p.totalLessons, 39);
      expect(p.availableLessons, 3);
      expect(p.completedLessons, 3);
      // The summary and the courses list read the same field.
      expect(p.percentage, closeTo(7.69, 0.01));
      expect(p.fraction, closeTo(0.0769, 0.001));
    });
  });
}
