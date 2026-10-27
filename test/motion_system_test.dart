import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/contact/views/faq_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/app_motion.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';

/// The motion system (2026-10-24, lib/shared/app_motion.dart): one way for
/// screens to arrive, tabs to switch, cards to answer a finger and figures to
/// land — each of which must be instant when the device asks to reduce motion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_secure_storage (read by HomeView behind the tab bar) has no
    // platform channel in a widget test; "no token" is enough.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  /// An Arabic, right-to-left app with the real page transitions.
  Widget app(Widget home, {bool reduceMotion = false}) => MaterialApp(
    locale: const Locale('ar'),
    theme: ThemeData(
      platform: TargetPlatform.android,
      pageTransitionsTheme: AppMotion.pageTransitions,
    ),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
    ),
    home: home,
  );

  Widget launcher(Route<void> Function() route) => Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(route()),
          child: const Text('open'),
        ),
      ),
    ),
  );

  Route<void> plainPush() => MaterialPageRoute(
    builder: (_) => const Scaffold(body: Center(child: Text('next'))),
  );

  group('pushed screens (shared axis)', () {
    testWidgets('slide in from the reading direction — left, in Arabic', (
      tester,
    ) async {
      await tester.pumpWidget(app(launcher(plainPush)));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final midway = tester.getCenter(find.text('next')).dx;
      await tester.pumpAndSettle();
      final settled = tester.getCenter(find.text('next')).dx;

      expect(
        midway,
        lessThan(settled),
        reason: 'RTL: forward comes from the left',
      );
      expect(
        settled - midway,
        lessThan(800 * 0.08 + 1),
        reason: 'a short slide, not a full-width one',
      );
    });

    testWidgets('appear in place with reduced motion', (tester) async {
      await tester.pumpWidget(app(launcher(plainPush), reduceMotion: true));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final midway = tester.getCenter(find.text('next')).dx;
      await tester.pumpAndSettle();

      expect(tester.getCenter(find.text('next')).dx, midway);
    });

    test('iOS keeps the native transition and its back swipe', () {
      expect(
        AppMotion.pageTransitions.builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
      );
      expect(
        AppMotion.pageTransitions.builders[TargetPlatform.android],
        isA<SharedAxisPageTransitionsBuilder>(),
      );
    });
  });

  group('tab switches (fade through)', () {
    Route<void> tabRoute() => TabSwitchRoute<void>(
      builder: (_) => const Scaffold(body: Center(child: Text('next'))),
    );

    testWidgets('fade rather than slide', (tester) async {
      await tester.pumpWidget(app(launcher(tabRoute)));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('next'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));

      final midway = tester.getCenter(find.text('next')).dx;
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.text('next')).dx,
        closeTo(midway, 4),
        reason: 'no horizontal travel',
      );
    });

    testWidgets('the bottom bar switches tabs with it', (tester) async {
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: Center(child: Text('المواد')),
            bottomNavigationBar: CustomBottomNavBar(current: NavTab.courses),
          ),
        ),
      );

      // The selected tab's icon sits on its lifted pill.
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ActiveTabIcon',
        ),
        findsOneWidget,
      );
    });
  });

  group('Pressable', () {
    double scale(WidgetTester tester) =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

    Widget card({bool reduceMotion = false}) => app(
      Scaffold(
        body: Center(
          child: Pressable(
            child: GestureDetector(
              onTap: () {},
              child: const SizedBox(
                width: 200,
                height: 80,
                child: Text('بطاقة'),
              ),
            ),
          ),
        ),
      ),
      reduceMotion: reduceMotion,
    );

    testWidgets('settles in while held and springs back on release', (
      tester,
    ) async {
      await tester.pumpWidget(card());
      expect(scale(tester), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('بطاقة')),
      );
      await tester.pump();
      expect(scale(tester), lessThan(1));

      await gesture.up();
      await tester.pump();
      expect(scale(tester), 1);
      await tester.pumpAndSettle();
    });

    testWidgets('a finger that starts scrolling releases the press', (
      tester,
    ) async {
      await tester.pumpWidget(card());
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('بطاقة')),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      expect(scale(tester), 1);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('does nothing with reduced motion', (tester) async {
      await tester.pumpWidget(card(reduceMotion: true));
      expect(find.byType(AnimatedScale), findsNothing);
    });
  });

  group('CountUp', () {
    tearDown(() => AppMotion.countUp = false);

    Widget figure({bool reduceMotion = false}) => app(
      Scaffold(
        body: Center(
          child: CountUp(
            value: 42.5,
            finalText: '42.5%',
            during: (v) => '$v%',
            builder: (text) => Text(text),
          ),
        ),
      ),
      reduceMotion: reduceMotion,
    );

    testWidgets('counts up once and lands on the exact text', (tester) async {
      AppMotion.countUp = true;
      await tester.pumpWidget(figure());
      expect(find.text('0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('42.5%'), findsNothing, reason: 'still counting');

      await tester.pumpAndSettle();
      expect(find.text('42.5%'), findsOneWidget);
    });

    testWidgets('shows the figure at once with reduced motion', (tester) async {
      AppMotion.countUp = true;
      await tester.pumpWidget(figure(reduceMotion: true));
      expect(find.text('42.5%'), findsOneWidget);
    });

    testWidgets('is off under flutter test unless a test turns it on', (
      tester,
    ) async {
      expect(AppMotion.countUp, isFalse);
      await tester.pumpWidget(figure());
      expect(find.text('42.5%'), findsOneWidget);
    });
  });

  group('BrandBackdrop', () {
    tearDown(() => BrandBackdrop.ambientMotion = false);

    Matrix4 orb(WidgetTester tester, int i) => tester
        .widget<Transform>(find.byKey(ValueKey('brand-backdrop-orb-$i')))
        .transform;

    testWidgets('the orbs of light drift when motion is allowed', (
      tester,
    ) async {
      BrandBackdrop.ambientMotion = true;
      await tester.pumpWidget(
        app(const Scaffold(body: BrandBackdrop(child: SizedBox.expand()))),
      );

      final before = [for (var i = 0; i < 3; i++) orb(tester, i).clone()];
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      for (var i = 0; i < 3; i++) {
        expect(orb(tester, i), isNot(before[i]), reason: 'orb $i');
      }
      await tester.pumpWidget(const SizedBox()); // stops the timer
    });

    testWidgets('the general screens carry it — e.g. الأسئلة الشائعة', (
      tester,
    ) async {
      await tester.pumpWidget(app(const FaqView()));
      expect(find.byType(BrandBackdrop), findsOneWidget);
    });
  });
}
