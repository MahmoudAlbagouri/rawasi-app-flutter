import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';

Course course(String name) =>
    Course(id: 0, name: name, academicYear: '1', madhab: 'all');

void main() {
  group('Course.icon', () {
    test('maps every curriculum subject to its own icon', () {
      expect(course('القرآن الكريم').icon, Icons.auto_stories);
      expect(course('القرآن').icon, Icons.auto_stories);
      expect(course('الفقه الحنفي').icon, Icons.balance);
      expect(course('الفقه الشافعي').icon, Icons.balance);
      expect(course('الفقه').icon, Icons.balance);
      expect(course('التفسير').icon, Icons.manage_search);
      expect(course('الحديث').icon, Icons.format_quote);
      expect(course('التوحيد').icon, Icons.star);
      expect(course('الميراث').icon, Icons.account_tree);
      expect(course('المواريث').icon, Icons.account_tree);
    });

    test('tolerates diacritics, hamza forms and stray whitespace', () {
      expect(course('القُرْآنُ  الكَريم').icon, Icons.auto_stories);
      expect(course('  التّفسير ').icon, Icons.manage_search);
      expect(course('الفِقْه الحَنَفي').icon, Icons.balance);
    });

    test('falls back to the generic book for anything else', () {
      expect(course('النحو').icon, Icons.menu_book);
      expect(course('').icon, Icons.menu_book);
    });
  });

  group('Course.fromJson', () {
    test('reads term as a string and keeps whole-year courses null', () {
      final termCourse = Course.fromJson({
        'id': 7,
        'name': 'التفسير',
        'academic_year': '1',
        'madhab': 'all',
        'term': '2',
      });
      expect(termCourse.term, '2');

      final wholeYear = Course.fromJson({
        'id': 8,
        'name': 'الميراث',
        'academic_year': '3',
        'madhab': 'all',
        'term': null,
      });
      expect(wholeYear.term, isNull);
    });
  });
}

