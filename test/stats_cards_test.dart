import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/home/widgets/trial_card.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/features/stats/widgets/my_rank_card.dart';
import 'package:rawasi_app_n/shared/study_reminder_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Leaderboard _board({
  required int? myRank,
  required int myPoints,
  bool meInTop = false,
}) {
  return Leaderboard.fromJson({
    'scope': {'academic_year': '1', 'term': null},
    'top': [
      {
        'rank': 1,
        'student_id': 9,
        'name': 'زميل',
        'points': 40,
        'completed_lessons': 8,
        'is_current_student': false,
      },
      {
        'rank': 3,
        'student_id': 1,
        'name': 'أنا',
        'points': myPoints,
        'completed_lessons': 4,
        'is_current_student': meInTop,
      },
    ],
    'me': {'rank': myRank, 'points': myPoints},
  });
}

void main() {
  group('Trial model', () {
    test('an unactivated student has no trial to render', () {
      final t = Trial.fromJson({
        'started': false,
        'total_days': 30,
        'days_used': null,
        'days_remaining': null,
        'ends_at': null,
        'has_ended': false,
      });

      expect(t.started, isFalse);
      expect(t.isVisible, isFalse, reason: 'the card must hide entirely');
      expect(t.daysRemaining, isNull, reason: 'null, not zero');
    });

    test('mid-trial carries the server figures unchanged', () {
      final t = Trial.fromJson({
        'started': true,
        'total_days': 30,
        'days_used': 12,
        'days_remaining': 18,
        'ends_at': '2026-10-16',
        'has_ended': false,
      });

      expect(t.isVisible, isTrue);
      expect(t.daysUsed, 12);
      expect(t.daysRemaining, 18);
      expect(t.hasEnded, isFalse);
    });

    test('an older payload with no trial key still parses', () {
      final t = Trial.fromJson(const {});

      expect(t.started, isFalse);
      expect(t.isVisible, isFalse);
    });
  });

  group('TrialCard', () {
    testWidgets('renders nothing before activation', (tester) async {
      await tester.pumpWidget(_wrap(TrialCard(
        trial: Trial.fromJson(const {'started': false, 'total_days': 30}),
      )));
      await tester.pump();

      expect(find.textContaining('الفترة المجانية'), findsNothing);
    });

    testWidgets('mid-trial shows what is left, with no lockout language',
        (tester) async {
      await tester.pumpWidget(_wrap(TrialCard(
        trial: Trial.fromJson(const {
          'started': true, 'total_days': 30, 'days_used': 12,
          'days_remaining': 18, 'ends_at': '2026-10-16', 'has_ended': false,
        }),
      )));
      await tester.pumpAndSettle();

      expect(find.text('الفترة المجانية'), findsOneWidget);
      expect(find.textContaining('متبقي'), findsOneWidget);
      // Nothing is enforced at the end, so nothing may threaten the student.
      expect(find.textContaining('ستفقد'), findsNothing);
      expect(find.textContaining('سينتهي وصولك'), findsNothing);
    });

    testWidgets('past day 30 is informational, not a warning', (tester) async {
      await tester.pumpWidget(_wrap(TrialCard(
        trial: Trial.fromJson(const {
          'started': true, 'total_days': 30, 'days_used': 45,
          'days_remaining': 0, 'ends_at': '2026-09-13', 'has_ended': true,
        }),
      )));
      await tester.pumpAndSettle();

      expect(find.text('انتهت الفترة المجانية'), findsOneWidget);
      expect(find.textContaining('يمكنك متابعة الدراسة'), findsOneWidget);
      // No negative counter.
      expect(find.textContaining('-'), findsNothing);
    });
  });

  group('StudyReminderCard', () {
    Inactivity days(int? d) => Inactivity(delayDays: d);

    test('home only shows it once it is meaningful', () {
      expect(StudyReminderCard.shouldShowOnHome(days(null)), isFalse);
      expect(StudyReminderCard.shouldShowOnHome(days(0)), isFalse);
      expect(StudyReminderCard.shouldShowOnHome(days(1)), isFalse);
      expect(StudyReminderCard.shouldShowOnHome(days(2)), isTrue);
      expect(StudyReminderCard.shouldShowOnHome(days(9)), isTrue);
    });

    testWidgets('never-started and studied-today are distinct states',
        (tester) async {
      await tester.pumpWidget(_wrap(StudyReminderCard(inactivity: days(null))));
      await tester.pumpAndSettle();
      expect(find.text('لم تبدأ بعد'), findsOneWidget);

      await tester.pumpWidget(_wrap(StudyReminderCard(inactivity: days(0))));
      await tester.pumpAndSettle();
      expect(find.text('درست اليوم'), findsOneWidget);
    });

    testWidgets('counts elapsed days with Arabic plurals', (tester) async {
      for (final (d, expected) in [
        (1, 'مر يوم منذ آخر درس'),
        (2, 'مر يومان منذ آخر درس'),
        (4, 'مر 4 أيام منذ آخر درس'),
        (15, 'مر 15 يومًا منذ آخر درس'),
      ]) {
        await tester.pumpWidget(_wrap(StudyReminderCard(inactivity: days(d))));
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget, reason: 'for $d days');
      }
    });

    testWidgets('makes no claim about lesson unlocking', (tester) async {
      // The 3-day auto-unlock runs on a different clock (previousUnlockedAt),
      // so this card cannot know whether the next lesson opened — and must not
      // say it did. It also must not frame anything as lost.
      await tester.pumpWidget(_wrap(StudyReminderCard(inactivity: days(6))));
      await tester.pumpAndSettle();

      expect(find.textContaining('مفتوح'), findsNothing);
      expect(find.textContaining('ستفقد'), findsNothing);
      expect(find.textContaining('تبقى'), findsNothing);
      expect(find.textContaining('واصل رحلتك'), findsOneWidget);
    });

    testWidgets('is tappable when a destination is given', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(StudyReminderCard(
        inactivity: days(4),
        compact: true,
        onContinue: () => tapped = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('مر 4 أيام'));
      expect(tapped, isTrue);
    });
  });

  group('rank card', () {
    testWidgets('shows for a student inside the top ten', (tester) async {
      // The motivating case the old conditional append suppressed.
      await tester.pumpWidget(_wrap(
        MyRankCard(board: _board(myRank: 3, myPoints: 21, meInTop: true)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('أنت في المركز 3'), findsOneWidget);
      expect(find.text('21 نقطة'), findsOneWidget);
      expect(find.textContaining('ضمن أول عشرة'), findsOneWidget);
    });

    testWidgets('shows for a student outside the top ten', (tester) async {
      await tester.pumpWidget(_wrap(
        MyRankCard(board: _board(myRank: 42, myPoints: 5)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('أنت في المركز 42'), findsOneWidget);
      expect(find.text('5 نقاط'), findsOneWidget);
    });

    testWidgets('a zero-progress student gets an invitation, not a zero',
        (tester) async {
      await tester.pumpWidget(_wrap(
        MyRankCard(board: _board(myRank: null, myPoints: 0)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ابدأ بحل الأسئلة لدخول الترتيب'), findsOneWidget);
      expect(find.textContaining('المركز'), findsNothing);
      expect(find.text('0 نقاط'), findsNothing);
    });
  });
}
