import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_menu_list.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/features/home/widgets/guest_trial_banner.dart';
import 'package:rawasi_app_n/features/home/widgets/intro_video_card.dart';
import 'package:rawasi_app_n/shared/animated_item.dart';
import 'package:rawasi_app_n/shared/app_sounds.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/celebration_burst.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The 2026-10-17 polish: «كيف يعمل التطبيق؟» first on Home, interaction
/// sounds behind one switch, the ambient backdrop motion and the lesson
/// celebration — each of which must stay still when the device asks to
/// reduce motion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home, {bool reduceMotion = false}) => MaterialApp(
    locale: const Locale('ar'),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: home,
    ),
  );

  group('AppSounds', () {
    final played = <AppSound>[];

    setUp(() {
      played.clear();
      AppSounds.debugOnPlay = played.add;
      AppSounds.enabled.value = true;
    });

    tearDown(() {
      AppSounds.debugOnPlay = null;
      AppSounds.enabled.value = true;
    });

    test('plays while the switch is on', () {
      AppSounds.play(AppSound.easy);
      expect(played, [AppSound.easy]);
    });

    test('is silent while the switch is off', () {
      AppSounds.enabled.value = false;
      AppSounds.play(AppSound.lessonComplete);
      expect(played, isEmpty);
    });

    test('remembers the switch on the device, and reads it back', () async {
      SharedPreferences.setMockInitialValues({});

      await AppSounds.setEnabled(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppSounds.prefKey), isFalse);

      AppSounds.enabled.value = true; // as on a fresh start…
      await AppSounds.init(); // …the saved choice wins
      expect(AppSounds.enabled.value, isFalse);
    });

    test('is on by default', () async {
      SharedPreferences.setMockInitialValues({});
      AppSounds.enabled.value = false;
      await AppSounds.init();
      expect(AppSounds.enabled.value, isTrue);
    });

    test('every sound has a bundled asset', () {
      for (final s in AppSound.values) {
        expect(s.assetPath, startsWith('sounds/'), reason: s.name);
        expect(s.volume, inInclusiveRange(0.1, 1.0), reason: s.name);
      }
    });
  });

  group('«أصوات التفاعل» in حسابي', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppSounds.enabled.value = true;
    });
    tearDown(() {
      AppSounds.debugOnPlay = null;
      AppSounds.enabled.value = true;
    });

    testWidgets('the switch turns the sounds off and on again', (tester) async {
      final played = <AppSound>[];
      AppSounds.debugOnPlay = played.add;

      await tester.pumpWidget(
        app(Scaffold(body: ProfileMenuList(onLogout: () {}))),
      );
      await tester.pumpAndSettle();

      expect(find.text('أصوات التفاعل'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(AppSounds.enabled.value, isFalse);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(played, isEmpty, reason: 'turning it off makes no sound');

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(AppSounds.enabled.value, isTrue);
      expect(played, hasLength(1), reason: 'turning it on plays a sample');
    });
  });

  group('BrandBackdrop ambient motion', () {
    tearDown(() => BrandBackdrop.ambientMotion = false);

    Offset latticeOffset(WidgetTester tester) {
      final t = tester.widget<Transform>(
        find.byKey(const ValueKey('brand-backdrop-lattice')),
      );
      return Offset(
        t.transform.getTranslation().x,
        t.transform.getTranslation().y,
      );
    }

    Widget backdrop({bool reduceMotion = false}) => app(
      const Scaffold(body: BrandBackdrop(child: SizedBox.expand())),
      reduceMotion: reduceMotion,
    );

    testWidgets('drifts when allowed', (tester) async {
      BrandBackdrop.ambientMotion = true;
      await tester.pumpWidget(backdrop());
      final before = latticeOffset(tester);

      // The motion runs off a real-time clock; let some real time pass.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(latticeOffset(tester), isNot(before));

      await tester.pumpWidget(const SizedBox()); // stops the timer
    });

    testWidgets('stays still when the device asks to reduce motion', (
      tester,
    ) async {
      BrandBackdrop.ambientMotion = true;
      await tester.pumpWidget(backdrop(reduceMotion: true));

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(latticeOffset(tester), Offset.zero);
    });

    testWidgets('is off under flutter test unless a test turns it on', (
      tester,
    ) async {
      expect(BrandBackdrop.ambientMotion, isFalse);
      await tester.pumpWidget(backdrop());
      await tester.pumpAndSettle(); // would never settle if it looped
      expect(latticeOffset(tester), Offset.zero);
    });
  });

  group('CelebrationBurst', () {
    const icon = Icon(Icons.verified, key: ValueKey('icon'), size: 84);

    double iconScale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.byKey(const ValueKey('icon')),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale
        .value;

    testWidgets('plays once and settles with the icon at full size', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const Center(child: CelebrationBurst(child: icon))),
      );
      expect(iconScale(tester), lessThan(1));

      await tester.pumpAndSettle(); // finite: it never loops
      expect(iconScale(tester), 1);
    });

    testWidgets('with reduced motion, the icon is simply shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const Center(child: CelebrationBurst(child: icon)),
          reduceMotion: true,
        ),
      );
      expect(iconScale(tester), 1);
    });

    test('uses brand colours only', () {
      expect(CelebrationBurst.palette, hasLength(4));
    });
  });

  group('StaggerOnce', () {
    testWidgets('animates the first rows and keeps the same widget type '
        'for every row', (tester) async {
      final stagger = StaggerOnce(maxItems: 2);
      final rows = [for (var i = 0; i < 4; i++) stagger.wrap(i, Text('$i'))];

      // Every row is an AnimatedItem — a rebuild after the window must not
      // swap the widget type and remount the row.
      expect(rows, everyElement(isA<AnimatedItem>()));
      expect((rows[0] as AnimatedItem).animate, isTrue);
      expect((rows[1] as AnimatedItem).animate, isTrue);
      expect((rows[2] as AnimatedItem).animate, isFalse);
      expect((rows[3] as AnimatedItem).animate, isFalse);

      await tester.pumpWidget(app(Column(children: rows)));
      // A settled row is fully visible on its very first frame.
      final settled = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('3'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(settled.opacity.value, 1);
      await tester.pumpAndSettle();
    });
  });

  group('Home', () {
    setUp(() {
      // No token: HomeView resolves to its signed-out state with no network.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (call) async => null,
          );
    });

    testWidgets('«كيف يعمل التطبيق؟» is the first card, above the guest '
        'promo and «إنجازك حتى الآن»', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(const HomeView()));
      await tester.pumpAndSettle();

      final intro = tester.getTopLeft(find.byType(IntroVideoCard)).dy;
      final promo = tester.getTopLeft(find.byType(GuestTrialBanner)).dy;
      final stats = tester.getTopLeft(find.text('إنجازك حتى الآن').first).dy;

      expect(intro, lessThan(promo));
      expect(intro, lessThan(stats));
    });
  });
}
