import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';

void main() {
  test('leaderboard scope and per-entry lessons parse from the live shape', () {
    final path = Platform.environment['STATS_JSON'];
    if (path == null) return; // only meaningful with a captured response
    final body = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final s = StudentStats.fromJson(body['data'] as Map<String, dynamic>);

    expect(s.leaderboard.scopeYear, '1');
    expect(s.leaderboard.scopeTerm, '1');
    expect(s.leaderboard.scopeLabel, 'الصف الأول الثانوي — الفصل الأول');
    expect(s.leaderboard.top.first.completedLessons, 0);
    expect(s.leaderboard.top.first.points, 1);
    expect(s.subjects.map((x) => x.key), contains('fiqh_hanafi'));
  });

  test('grade 3 scope label has no term', () {
    final b = Leaderboard.fromJson({'scope': {'academic_year': '3', 'term': null}, 'top': [], 'me': {}});
    expect(b.scopeLabel, 'الصف الثالث الثانوي');
  });

  // The card that read "لم تبدأ بعد" for every student: the label was always
  // right, the seconds behind it were always 0 because the app never sent a
  // duration. These pin the render leg of that chain.
  group('TimeSpent.label', () {
    String label(int seconds) => TimeSpent(
          seconds: seconds,
          minutes: (seconds / 60).round(),
          hours: seconds / 3600,
        ).label;

    test('nothing recorded still reads "لم تبدأ بعد"', () {
      expect(label(0), 'لم تبدأ بعد');
    });

    test('a real completion reads as minutes', () {
      expect(label(180), '3 دقيقة');
    });

    test('under a minute reads as seconds, not as "not started"', () {
      expect(label(45), '45 ثانية');
    });

    test('hours and minutes are combined', () {
      expect(label(3720), '1 ساعة و 2 دقيقة');
      expect(label(7200), '2 ساعة');
    });
  });
}
