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
}
