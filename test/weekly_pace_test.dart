import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';

/// The "6 / 2" figure: lessons finished over the week of studying the student
/// is in.
Pacing _pacing({
  required int completed,
  required int weeks,
  double? rate,
  int remaining = 100,
  String? projected,
}) =>
    Pacing.fromJson({
      'lessons_per_week': rate ?? (weeks == 0 ? 0 : completed / weeks),
      'weeks_elapsed': weeks,
      'completed_lessons': completed,
      'remaining_lessons': remaining,
      'estimated_completion_date': projected,
    });

void main() {
  group('the ratio', () {
    test('one lesson in the first week is 1 / 1', () {
      expect(_pacing(completed: 1, weeks: 1).ratioLabel, '1 / 1');
    });

    test('two lessons in the first week is 2 / 1', () {
      expect(_pacing(completed: 2, weeks: 1).ratioLabel, '2 / 1');
    });

    test('six lessons over the first two weeks is 6 / 2', () {
      expect(_pacing(completed: 6, weeks: 2).ratioLabel, '6 / 2');
    });

    test('the numerator is lessons and the denominator weeks, never swapped',
        () {
      // Easy to invert, and silent when inverted: 2/6 and 6/2 are both
      // plausible-looking strings.
      final p = _pacing(completed: 6, weeks: 2);

      expect(p.ratioLabel.split(' / ').first, '6');
      expect(p.ratioLabel.split(' / ').last, '2');
    });
  });

  group('not started', () {
    test('zero weeks is not a ratio', () {
      final p = _pacing(completed: 0, weeks: 0);

      expect(p.hasStarted, isFalse);
      expect(p.lessonsPerWeek, 0);
    });

    test('a payload with no weeks_elapsed key still parses', () {
      // An older backend, or an older cached response.
      final p = Pacing.fromJson(const {
        'lessons_per_week': 0,
        'remaining_lessons': 175,
      });

      expect(p.weeksElapsed, 0);
      expect(p.hasStarted, isFalse);
    });

    test('one week with nothing done has started', () {
      expect(_pacing(completed: 0, weeks: 1).hasStarted, isTrue);
    });

    test('progress with no weeks reported never prints a zero denominator', () {
      // An older backend, or a response cached from one, would otherwise pair
      // real lessons with weeks_elapsed 0 and the card would read "5 / 0".
      final p = Pacing.fromJson(const {
        'lessons_per_week': 0,
        'completed_lessons': 5,
        'remaining_lessons': 170,
      });

      expect(p.weeksElapsed, 1);
      expect(p.ratioLabel, '5 / 1');
      expect(p.hasStarted, isTrue);
    });

    test('zero weeks survives when there is genuinely nothing done', () {
      // The floor must not turn "not started" into "week one", which would put
      // a 0 / 1 ratio on screen instead of the empty state.
      final p = Pacing.fromJson(const {
        'lessons_per_week': 0,
        'completed_lessons': 0,
        'weeks_elapsed': 0,
        'remaining_lessons': 175,
      });

      expect(p.weeksElapsed, 0);
      expect(p.hasStarted, isFalse);
    });
  });

  group('the rate agrees with the ratio', () {
    test('6 over 2 weeks is 3 per week', () {
      expect(_pacing(completed: 6, weeks: 2).lessonsPerWeek, 3.0);
    });

    test('the rate never exceeds the lessons actually completed', () {
      // The regression the old fractional denominator caused: one lesson on
      // day one came back as 7.0 per week, because a day was treated as a
      // seventh of a week. The app needed a "معدل مبدئي" caption to apologise
      // for it. With whole weeks counted from one it cannot happen.
      for (final weeks in [1, 2, 5]) {
        final p = _pacing(completed: 1, weeks: weeks);
        expect(
          p.lessonsPerWeek,
          lessThanOrEqualTo(p.completedLessons.toDouble()),
          reason: 'week $weeks',
        );
      }
    });
  });

  group('arabicWeeks', () {
    test('reads correctly after a preposition', () {
      // "في أسبوعين", not "في أسبوعان" — the dual after في is genitive.
      expect(arabicWeeks(1), 'أسبوع');
      expect(arabicWeeks(2), 'أسبوعين');
      expect(arabicWeeks(3), '3 أسابيع');
      expect(arabicWeeks(10), '10 أسابيع');
      expect(arabicWeeks(15), '15 أسبوعًا');
    });
  });

  group('rendering direction', () {
    testWidgets('the ratio is laid out left to right inside an RTL screen',
        (tester) async {
      // Without an explicit LTR Directionality the bidi algorithm resolves the
      // slash and its spaces to the paragraph direction, so "6 / 2" displays
      // as "2 / 6" — the same characters making the opposite claim.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            locale: const Locale('ar'),
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(_pacing(completed: 6, weeks: 2).ratioLabel),
              ),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, '6 / 2');

      final direction = Directionality.of(
        tester.element(find.byType(Text)),
      );
      expect(direction, TextDirection.ltr);
    });
  });
}
