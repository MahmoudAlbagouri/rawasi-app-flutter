import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';

void main() {
  test('Course.fromJson reads progress from the live /courses shape', () {
    final path = Platform.environment['COURSES_JSON'];
    if (path == null) return;
    final body = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final courses = (body['data'] as List).map((c) => Course.fromJson(c as Map<String, dynamic>)).toList();
    expect(courses, isNotEmpty);
    for (final c in courses) {
      expect(c.progress, isNotNull, reason: c.name);
      expect(c.progress!.totalLessons, greaterThan(0), reason: '${c.name} uses the curriculum total');
      expect(c.progress!.fraction, inInclusiveRange(0, 1));
    }
    final tafseer = courses.firstWhere((c) => c.name == 'التفسير');
    expect(tafseer.progress!.totalLessons, 39);
  });

  test('progress is null when the API omits it, and whole-number percentages parse', () {
    expect(Course.fromJson({'id': 1, 'name': 'x'}).progress, isNull);
    final p = CourseProgress.fromJson({'completed_lessons': 2, 'total_lessons': 50, 'available_lessons': 4, 'percentage': 4});
    expect(p.percentage, 4.0);
    expect(p.fraction, 0.04);
  });
}
