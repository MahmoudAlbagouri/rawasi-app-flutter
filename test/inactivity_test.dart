import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';

void main() {
  group('Inactivity parsing', () {
    test('reads the analytics block', () {
      final a = Inactivity.fromJson({
        'last_study_date': '2026-09-20',
        'delay_days': 4,
      });

      expect(a.lastStudyDate, '2026-09-20');
      expect(a.delayDays, 4);
      expect(a.hasStarted, isTrue);
    });

    test('a null delay stays null rather than becoming zero', () {
      // The difference matters: null is "never started", 0 is "studied today".
      final a = Inactivity.fromJson({
        'last_study_date': null,
        'delay_days': null,
      });

      expect(a.delayDays, isNull);
      expect(a.hasStarted, isFalse);
    });

    test('an older payload with no inactivity key still parses', () {
      final a = Inactivity.fromJson(const {});

      expect(a.delayDays, isNull);
      expect(a.label, 'لم تبدأ بعد');
    });

    test('a delay sent as a string parses', () {
      expect(Inactivity.fromJson({'delay_days': '7'}).delayDays, 7);
    });
  });

  group('Inactivity copy', () {
    String label(int? days) =>
        Inactivity(delayDays: days).label;
    String hint(int? days) => Inactivity(delayDays: days).hint;

    test('never started uses the same idiom as the study-time card', () {
      expect(label(null), 'لم تبدأ بعد');
    });

    test('studied today is encouragement, not a count', () {
      expect(label(0), 'درست اليوم');
      expect(hint(0), 'واصل التقدم');
    });

    test('counts are pluralised properly in Arabic', () {
      expect(label(1), 'مر يوم منذ آخر درس');
      expect(label(2), 'مر يومان منذ آخر درس');
      expect(label(5), 'مر 5 أيام منذ آخر درس');
      expect(label(15), 'مر 15 يومًا منذ آخر درس');
    });

    test('past three days the copy reflects the auto-unlock rule', () {
      // The next lesson opens by itself after 3 days, so "you are behind"
      // would be untrue as well as discouraging.
      expect(hint(1), 'عُد لإكمال ما بدأته');
      expect(hint(3), 'الدرس التالي مفتوح لك الآن');
      expect(hint(10), 'الدرس التالي مفتوح لك الآن');
    });
  });

  group('Arabic counted nouns', () {
    test('days follow the singular/dual/plural/accusative rule', () {
      expect(arabicDays(1), 'يوم');
      expect(arabicDays(2), 'يومان');
      expect(arabicDays(3), '3 أيام');
      expect(arabicDays(10), '10 أيام');
      expect(arabicDays(11), '11 يومًا');
      expect(arabicDays(0), '0 أيام');
    });

    test('points keep their number, including one and two', () {
      // "1 نقطة" on a leaderboard row reads better than a bare "نقطة".
      expect(arabicPoints(1), '1 نقطة');
      expect(arabicPoints(2), '2 نقطتان');
      expect(arabicPoints(5), '5 نقاط');
      expect(arabicPoints(15), '15 نقطة');
    });

    test('lessons pluralise too', () {
      expect(arabicLessons(1), '1 درس');
      expect(arabicLessons(4), '4 دروس');
      expect(arabicLessons(12), '12 درسًا');
    });
  });

  group('Arabic dates', () {
    test('an ISO date becomes a readable Arabic one', () {
      // estimated_completion_date arrives as a raw Y-m-d string.
      expect(arabicDate('2026-09-24'), '24 سبتمبر 2026');
      expect(arabicDate('2027-01-03'), '3 يناير 2027');
    });

    test('null and unparseable input fall back rather than print rubbish', () {
      expect(arabicDate(null), isNull);
      expect(arabicDate(''), isNull);
      expect(arabicDate('not a date'), isNull);
    });
  });

  group('Pacing', () {
    test('carries completed_lessons so a first-day burst can be spotted', () {
      // One lesson done on day one reads as 7/week: the rate outruns the work.
      final p = Pacing.fromJson({
        'lessons_per_week': 7.0,
        'remaining_lessons': 174,
        'completed_lessons': 1,
        'estimated_completion_date': '2027-01-01',
      });

      expect(p.lessonsPerWeek, 7.0);
      expect(p.completedLessons, 1);
      expect(p.lessonsPerWeek > p.completedLessons, isTrue,
          reason: 'this is the condition the card captions as provisional');
    });

    test('a settled pace does not trip the provisional caption', () {
      final p = Pacing.fromJson({
        'lessons_per_week': 0.5,
        'remaining_lessons': 100,
        'completed_lessons': 1,
      });

      expect(p.lessonsPerWeek > p.completedLessons, isFalse);
      expect(p.estimatedCompletionDate, isNull);
    });
  });

  group('Leaderboard', () {
    test('scope term is null now that the board is year-wide', () {
      final b = Leaderboard.fromJson({
        'scope': {'academic_year': '1', 'term': null},
        'top': [
          {
            'rank': 1,
            'student_id': 2,
            'name': 'طالب',
            'points': 5,
            'completed_lessons': 1,
            'is_current_student': false,
          },
        ],
        'me': {'rank': 2, 'points': 3},
      });

      expect(b.scopeYear, '1');
      expect(b.scopeTerm, isNull);
      expect(b.top, hasLength(1));
      expect(b.myRank, 2);
    });

    test('an empty board carries no rank', () {
      final b = Leaderboard.fromJson({
        'scope': {'academic_year': '1', 'term': null},
        'top': const [],
        'me': {'rank': null, 'points': 0},
      });

      expect(b.top, isEmpty);
      expect(b.myRank, isNull);
    });
  });
}
