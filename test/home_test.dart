import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';
import 'package:rawasi_app_n/features/home/widgets/library_preview.dart';
import 'package:rawasi_app_n/features/home/widgets/stats_summary_card.dart';
import 'package:rawasi_app_n/features/courses/data/subject_group.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

Course _course(
  int id,
  String name, {
  String? term,
  double percent = 0,
  int completed = 0,
  int total = 39,
  int available = 6,
}) =>
    Course.fromJson({
      'id': id,
      'name': name,
      'academic_year': '1',
      'madhab': 'all',
      'term': term,
      'progress': {
        'completed_lessons': completed,
        'total_lessons': total,
        'available_lessons': available,
        'percentage': percent,
      },
    });

/// A course the API returned without a progress block.
Course _bareCourse(int id, String name) => Course.fromJson({
      'id': id,
      'name': name,
      'academic_year': '1',
      'madhab': 'all',
      'term': null,
    });

SubjectProgress _subject(String label, int done, int total) =>
    SubjectProgress.fromJson({
      'key': label,
      'label': label,
      'unit': 'lesson',
      'completed_lessons': done,
      'total_lessons': total,
      'remaining_lessons': total - done,
      'available_lessons': total,
      'percentage': total == 0 ? 0 : (done / total * 100),
    });

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('ar'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('completion figure', () {
    test('home and إحصائياتي render the identical string', () {
      // The whole point of Completion.percentLabel: one formatter, so the two
      // screens cannot print the same number to different precision. Home used
      // to show Student.progress, a different statistic entirely.
      final c = Completion.fromJson({
        'completed_lessons': 5,
        'total_lessons': 175,
        'remaining_lessons': 170,
        'percentage': 2.9,
      });

      expect(c.percentLabel, '2.9');
      expect(c.fraction, closeTo(0.029, 0.0001));
    });

    test('a whole number loses its trailing .0', () {
      final c = Completion.fromJson({
        'completed_lessons': 70,
        'total_lessons': 175,
        'remaining_lessons': 105,
        'percentage': 40.0,
      });

      expect(c.percentLabel, '40');
    });

    test('fraction is clamped for a progress indicator', () {
      final c = Completion.fromJson({'percentage': 140.0});
      expect(c.fraction, 1.0);
    });
  });

  group('subject grouping', () {
    test('both terms of one subject collapse into a single card', () {
      // The reported bug: grades 1-2 are returned both terms of every subject,
      // so the raw list rendered "التفسير" twice, "التوحيد" twice, and so on.
      final groups = groupCoursesBySubject([
        _course(1, 'التفسير', term: '1'),
        _course(2, 'التفسير', term: '2'),
        _course(3, 'الحديث', term: '1'),
        _course(4, 'الحديث', term: '2'),
      ]);

      expect(groups, hasLength(2), reason: '4 course rows, 2 subjects');
      expect(groups.map((g) => g.name), ['التفسير', 'الحديث']..sort());
    });

    test('the total is NOT summed across terms', () {
      // Each term row already carries the whole-subject total (39), so summing
      // would show 78 and halve every percentage.
      final groups = groupCoursesBySubject([
        _course(1, 'التفسير', term: '1', completed: 1, total: 39, available: 4),
        _course(2, 'التفسير', term: '2', completed: 0, total: 39, available: 0),
      ]);

      expect(groups.single.totalLessons, 39);
      expect(groups.single.countLabel, '1 من 39');
    });

    test('completed and available ARE summed across terms', () {
      // Each course owns its own lessons, so these do not overlap.
      final groups = groupCoursesBySubject([
        _course(1, 'التفسير', term: '1', completed: 2, total: 39, available: 4),
        _course(2, 'التفسير', term: '2', completed: 3, total: 39, available: 6),
      ]);

      expect(groups.single.completedLessons, 5);
      expect(groups.single.availableLessons, 10);
      expect(groups.single.percentage, closeTo(5 / 39 * 100, 0.01));
    });

    test('grade 3 has one term and is unaffected', () {
      final groups = groupCoursesBySubject([
        _course(1, 'الميراث', completed: 10, total: 10, available: 10),
      ]);

      expect(groups.single.totalLessons, 10);
      expect(groups.single.completedLessons, 10);
    });

    test('tapping opens the first term still incomplete', () {
      final groups = groupCoursesBySubject([
        _course(1, 'التفسير', term: '1', percent: 100),
        _course(2, 'التفسير', term: '2', percent: 20),
      ]);

      expect(groups.single.target.id, 2, reason: 'not always term 1');
    });

    test('falls back to the first course when everything is complete', () {
      final groups = groupCoursesBySubject([
        _course(1, 'التفسير', term: '1', percent: 100),
        _course(2, 'التفسير', term: '2', percent: 100),
      ]);

      expect(groups.single.target.id, 1);
    });

    test('a course with no progress payload still renders and opens', () {
      final groups = groupCoursesBySubject([_bareCourse(9, 'مادة جديدة')]);

      expect(groups.single.hasProgress, isFalse);
      expect(groups.single.countLabel, isNull);
      expect(groups.single.target.id, 9);
    });
  });

  group('library preview', () {
    test('caps at three and orders by saved count', () {
      final ordered = libraryPreviewOrder([
        SubjectItem(id: 1, name: 'أ', savedQuestionsCount: 2),
        SubjectItem(id: 2, name: 'ب', savedQuestionsCount: 9),
        SubjectItem(id: 3, name: 'ج', savedQuestionsCount: 5),
        SubjectItem(id: 4, name: 'د', savedQuestionsCount: 1),
      ]);

      expect(ordered.map((s) => s.name), ['ب', 'ج', 'أ']);
      expect(ordered, hasLength(kLibraryPreviewCount));
    });

    test('does not mutate the caller list', () {
      final source = [
        SubjectItem(id: 1, name: 'أ', savedQuestionsCount: 1),
        SubjectItem(id: 2, name: 'ب', savedQuestionsCount: 9),
      ];

      libraryPreviewOrder(source);

      expect(source.first.name, 'أ');
    });

    test('an empty library orders to nothing rather than throwing', () {
      expect(libraryPreviewOrder(const []), isEmpty);
    });
  });

  group('HomeData', () {
    test('a signed-out load carries no sections', () {
      final d = HomeData.signedOut();

      expect(d.isSignedIn, isFalse);
      expect(d.profile, isNull);
      expect(d.stats, isNull);
      expect(d.courses, isNull);
      expect(d.library, isNull);
    });

    test('freshness expires', () {
      final stale = HomeData(
        isSignedIn: true,
        profile: null,
        stats: null,
        courses: null,
        library: null,
        loadedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(stale.isFresh, isFalse);
    });
  });

  group('the two states that break', () {
    testWidgets('inactive student: stats placeholder, never an error',
        (tester) async {
      // /analytics sits behind CheckStudentActive, so it 403s for a student
      // awaiting activation. That must read as a calm placeholder.
      await tester.pumpWidget(_wrap(const StatsSummaryPlaceholder()));
      await tester.pump();

      expect(find.text('إنجازك حتى الآن'), findsOneWidget);
      expect(
        find.text('ستظهر إحصائياتك هنا بمجرد تفعيل حسابك وبدء أول درس.'),
        findsOneWidget,
      );
      // Nothing that looks like a failure.
      expect(find.textContaining('خطأ'), findsNothing);
      expect(find.textContaining('فشل'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('inactive student: the loading skeleton reserves space',
        (tester) async {
      await tester.pumpWidget(_wrap(const StatsSummaryPlaceholder(loading: true)));
      await tester.pump();

      // Space is held so the layout does not jump when data lands.
      expect(find.byType(SkeletonBar), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('brand-new student: zero progress renders a full card',
        (tester) async {
      final stats = StudentStats.fromJson({
        'completion': {
          'completed_lessons': 0,
          'total_lessons': 175,
          'remaining_lessons': 175,
          'percentage': 0,
        },
        'subjects': [],
        'streak': {'current': 0, 'longest': 0},
        'time_spent': {'seconds': 0, 'minutes': 0, 'hours': 0},
        'pacing': {'lessons_per_week': 0, 'remaining_lessons': 175},
        'leaderboard': {
          'scope': {'academic_year': '1', 'term': null},
          'top': [],
          'me': {'rank': null, 'points': 0},
        },
        'inactivity': {'last_study_date': null, 'delay_days': null},
      });

      await tester.pumpWidget(
        _wrap(StatsSummaryCard(stats: stats, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0 من 175'), findsOneWidget);
      // "لم تبدأ بعد" for study time, and no streak nudge invented from zero.
      // (The static tile label 'أيام متتالية' is always there; what must be
      // absent is the encouragement banner, which needs a real streak.)
      expect(find.text('لم تبدأ بعد'), findsOneWidget);
      expect(find.textContaining('واصل، أنت في الطريق'), findsNothing);
      expect(find.textContaining('ترتيبك'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('brand-new student: empty library teaches instead of blanking',
        (tester) async {
      await tester.pumpWidget(_wrap(LibraryEmptyCard(onBrowse: () {})));
      await tester.pump();

      expect(find.text('مكتبتك تبدأ من هنا'), findsOneWidget);
      expect(
        find.textContaining('احفظ الأسئلة الصعبة أثناء حل الدروس'),
        findsOneWidget,
      );
      // And a way out of the empty state.
      expect(find.text('ابدأ درسًا وجرّب الحفظ'), findsOneWidget);
    });

    testWidgets('a student with a streak gets encouragement, not loss-pressure',
        (tester) async {
      final stats = StudentStats.fromJson({
        'completion': {
          'completed_lessons': 5,
          'total_lessons': 175,
          'remaining_lessons': 170,
          'percentage': 2.9,
        },
        'subjects': [],
        'streak': {'current': 2, 'longest': 4},
        'time_spent': {'seconds': 1800, 'minutes': 30, 'hours': 0.5},
        'pacing': {'lessons_per_week': 0.5, 'remaining_lessons': 170},
        'leaderboard': {
          'scope': {'academic_year': '1', 'term': null},
          'top': [],
          'me': {'rank': 3, 'points': 21},
        },
        'inactivity': {'last_study_date': '2026-09-24', 'delay_days': 0},
      });

      await tester.pumpWidget(
        _wrap(StatsSummaryCard(stats: stats, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('2.9%'), findsOneWidget);
      expect(find.textContaining('واصل، أنت في الطريق'), findsOneWidget);
      // Nothing about breaking or losing the streak.
      expect(find.textContaining('لا تكسر'), findsNothing);
      expect(find.textContaining('ستفقد'), findsNothing);
    });

    testWidgets('tapping the summary opens the full statistics screen',
        (tester) async {
      var tapped = false;
      final stats = StudentStats.fromJson({
        'completion': <String, dynamic>{
          'percentage': 10.0,
          'completed_lessons': 1,
          'total_lessons': 10,
          'remaining_lessons': 9,
        },
        'subjects': [],
        'streak': {'current': 0, 'longest': 0},
        'time_spent': {'seconds': 0, 'minutes': 0, 'hours': 0},
        'pacing': {'lessons_per_week': 0, 'remaining_lessons': 9},
        'leaderboard': <String, dynamic>{
          'scope': <String, dynamic>{},
          'top': [],
          'me': <String, dynamic>{},
        },
        'inactivity': <String, dynamic>{},
      });

      await tester.pumpWidget(
        _wrap(StatsSummaryCard(stats: stats, onTap: () => tapped = true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إنجازك حتى الآن'));
      expect(tapped, isTrue);
    });
  });
}
