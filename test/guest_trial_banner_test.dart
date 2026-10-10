import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/contact/views/faq_view.dart';
import 'package:rawasi_app_n/features/home/widgets/guest_trial_banner.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';

/// The pre-registration promo a signed-out student sees on the landing screen,
/// and the rewritten answer to the first FAQ in حسابي.
void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ar'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('GuestTrialBanner', () {
    testWidgets('announces the 15-day free trial', (tester) async {
      await tester.pumpWidget(wrap(const GuestTrialBanner()));

      expect(
        find.text('سجّل الآن واحصل على 15 يومًا تجربة مجانية بالكامل'),
        findsOneWidget,
      );
      // The badge in the corner repeats the length, short.
      expect(find.text('15 يومًا مجانًا'), findsOneWidget);
    });

    testWidgets('says the offer is open to all three grades', (tester) async {
      await tester.pumpWidget(wrap(const GuestTrialBanner()));

      expect(find.textContaining('الصفوف الثلاثة'), findsOneWidget);
      for (final grade in ['الأول الثانوي', 'الثاني الثانوي', 'الثالث الثانوي']) {
        expect(find.text(grade), findsOneWidget, reason: grade);
      }
    });

    testWidgets('offers sign-up first and sign-in second', (tester) async {
      await tester.pumpWidget(wrap(const GuestTrialBanner()));

      expect(find.text(AuthActions.registerLabel), findsOneWidget);
      expect(find.text(AuthActions.loginLabel), findsOneWidget);

      final actions = tester.widget<AuthActions>(find.byType(AuthActions));
      expect(actions.primary, AuthAction.register);
    });

    testWidgets('claims no more than it delivers', (tester) async {
      // The free plan is capped at 25% of each subject as well as 15 days, so
      // the banner must not promise the whole curriculum.
      await tester.pumpWidget(wrap(const GuestTrialBanner()));

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');

      expect(texts, isNot(contains('كل المحتوى')));
      expect(texts, isNot(contains('المنهج كاملًا')));
    });

    testWidgets('fits a narrow phone without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const GuestTrialBanner()));

      expect(tester.takeException(), isNull);
    });
  });

  group('FAQ question 1', () {
    final first = faqItems.first;

    test('keeps its question', () {
      expect(first['question'], startsWith('ما هي الاستراتيجية الذهبية'));
    });

    test('carries the new answer with all five steps and the conclusion', () {
      final answer = first['answer']!;

      expect(answer, startsWith('لكي تستثمر نظام "رواسي" بأفضل طريقة ممكنة'));
      for (final step in [
        '1- تلقَّ الشرح أولاً',
        '2- التجهيز الفوري للحل',
        '3- تصفية الأسئلة الصعبة',
        '4- تكرار الدورة (التدوير)',
        '5- الفرم النهائي',
      ]) {
        expect(answer, contains(step), reason: step);
      }
      expect(answer, contains('النتيجة؟'));
      expect(answer, endsWith('بكل ثقة وأريحية تامة.'));
    });

    test('the old answer is gone', () {
      expect(first['answer'], isNot(contains('الخطوة الأولى (الانتظام والمتابعة)')));
      expect(first['answer'], isNot(contains('حاطط رجل على رجل')));
    });

    test('steps are separated by blank lines so they read as a list', () {
      expect(first['answer']!.split('\n\n').length, greaterThanOrEqualTo(7));
    });

    test('the other 20 entries are untouched', () {
      expect(faqItems, hasLength(21));
      expect(faqItems[1]['question'], 'هل تطبيق رواسي بيغطي كل مواد الثانوية الأزهرية؟');
      expect(faqItems.last['question'], startsWith('إيه اللي يميز رواسي'));
    });
  });
}
