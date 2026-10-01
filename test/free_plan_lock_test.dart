import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/lesson.dart';

/// A student on the free plan reaches the first 25% of each subject. Beyond
/// that, lessons arrive locked with `requires_payment`, and the app has to tell
/// that lock apart from the ordinary sequential one — the two need different
/// sentences, because only one of them is something the student can act on
/// today.
Map<String, dynamic> _json({
  String status = 'locked',
  bool unlocked = false,
  bool completed = false,
  bool? requiresPayment,
  int? freeLimit,
}) =>
    {
      'id': 7,
      'course_id': 3,
      'title': 'الدرس السابع',
      'order': 7,
      'status': status,
      'is_unlocked': unlocked,
      'is_completed': completed,
      'questions_count': 4,
      'completed_questions_count': 0,
      'unlocked_at': null,
      if (requiresPayment != null) 'requires_payment': requiresPayment,
      if (freeLimit != null) 'free_limit_lessons': freeLimit,
    };

void main() {
  group('parsing', () {
    test('a paywalled lesson carries the flag and the allowance', () {
      final lesson = Lesson.fromJson(_json(requiresPayment: true, freeLimit: 2));

      expect(lesson.requiresPayment, isTrue);
      expect(lesson.freeLimitLessons, 2);
      expect(lesson.isUnlocked, isFalse);
      expect(lesson.status, 'locked');
    });

    test('an ordinary sequential lock is not a paywall', () {
      final lesson = Lesson.fromJson(_json(requiresPayment: false, freeLimit: 2));

      expect(lesson.requiresPayment, isFalse);
      expect(
        lesson.freeLimitLessons,
        2,
        reason: 'the allowance is still reported, so the notice can be shown',
      );
    });

    test('a paid student has no allowance', () {
      final lesson = Lesson.fromJson(_json(status: 'unlocked', unlocked: true));

      expect(lesson.freeLimitLessons, isNull);
      expect(lesson.requiresPayment, isFalse);
    });

    test('an older payload without either key parses as uncapped', () {
      // The app must keep working against a backend that has not shipped this
      // yet, and must not invent a paywall where the server reported none.
      final lesson = Lesson.fromJson(_json(status: 'unlocked', unlocked: true));

      expect(lesson.requiresPayment, isFalse);
      expect(lesson.freeLimitLessons, isNull);
    });
  });

  group('the allowance notice', () {
    // The notice is shown when the course has more lessons than the allowance
    // covers. Expressed here as the condition the view uses, so the rule is
    // pinned even though the widget needs a repo to render.
    bool showNotice(List<Lesson> lessons) {
      final limit = lessons.first.freeLimitLessons;

      return limit != null && lessons.length > limit;
    }

    List<Lesson> course(int count, {int? freeLimit}) => List.generate(
          count,
          (i) => Lesson.fromJson({
            ..._json(freeLimit: freeLimit),
            'id': i + 1,
            'order': i + 1,
          }),
        );

    test('appears when lessons sit beyond the allowance', () {
      expect(showNotice(course(8, freeLimit: 2)), isTrue);
    });

    test('stays hidden for a paid student', () {
      expect(showNotice(course(8)), isFalse);
    });

    test('stays hidden when the allowance already covers everything', () {
      // Nothing is withheld, so saying "2 of 2 free" would be noise.
      expect(showNotice(course(2, freeLimit: 2)), isFalse);
    });
  });
}
