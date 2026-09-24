import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/auth/widgets/profile_flow_app_bar.dart';

/// A stand-in for a profile-flow step, using the shared chrome.
class _Step extends StatelessWidget {
  final bool isBusy;
  const _Step({this.isBusy = false});

  @override
  Widget build(BuildContext context) {
    return ProfileFlowPopScope(
      isBusy: isBusy,
      child: Scaffold(
        appBar: ProfileFlowAppBar(title: 'استكمال البيانات', isBusy: isBusy),
        body: const Center(child: Text('step body')),
      ),
    );
  }
}

Widget _app(Widget home) => MaterialApp(
      locale: const Locale('ar'),
      home: home,
      // The real roots pull the network in; stub them so the test only asserts
      // navigation, not what those screens render.
      routes: {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_secure_storage talks over a platform channel that does not exist
    // in a widget test; "no token" makes leaveProfileFlow choose the login root.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  group('back out of the profile flow', () {
    testWidgets('pops normally when there IS a route below', (tester) async {
      await tester.pumpWidget(_app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _Step()),
                ),
                child: const Text('open step'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open step'));
      await tester.pumpAndSettle();
      expect(find.text('step body'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Back returned to the previous screen — not a blank navigator.
      expect(find.text('open step'), findsOneWidget);
      expect(find.text('step body'), findsNothing);
    });

    testWidgets(
        'does NOT empty the navigator when the step is the only route '
        '(the old black-screen case)', (tester) async {
      // Reproduces login → pushAndRemoveUntil → step 4: nothing underneath.
      await tester.pumpWidget(_app(const _Step()));
      expect(Navigator.canPop(tester.element(find.text('step body'))), isFalse);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The old code popped the last route, leaving nothing rendered. The
      // guard routes to a real screen instead, so the step is gone AND
      // something replaced it.
      expect(find.text('step body'), findsNothing);
      expect(find.byType(Navigator), findsWidgets);
    });

    testWidgets('back and skip are disabled while a request is in flight',
        (tester) async {
      await tester.pumpWidget(_app(const _Step(isBusy: true)));

      final backButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.arrow_back),
          matching: find.byType(IconButton),
        ),
      );
      expect(backButton.onPressed, isNull, reason: 'back disabled while busy');

      final skip = tester.widget<TextButton>(
        find.ancestor(of: find.text('تخطي'), matching: find.byType(TextButton)),
      );
      expect(skip.onPressed, isNull, reason: 'skip disabled while busy');
    });

    testWidgets('system back is intercepted when there is nothing to pop',
        (tester) async {
      await tester.pumpWidget(_app(const _Step()));

      final popScope = tester.widget<PopScope<Object?>>(
        find.byWidgetPredicate((w) => w is PopScope<Object?>),
      );
      expect(popScope.canPop, isFalse,
          reason: 'Flutter must not pop the last route by itself');
    });
  });

  group('skip', () {
    testWidgets('appears on the actions side of every step', (tester) async {
      await tester.pumpWidget(_app(const _Step()));

      expect(find.text('تخطي'), findsOneWidget);

      // Same AppBar carries both, with skip in actions (opposite the arrow).
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('تخطي')),
          findsOneWidget);
    });

    testWidgets('can be hidden where skipping makes no sense', (tester) async {
      await tester.pumpWidget(_app(
        const Scaffold(appBar: ProfileFlowAppBar(title: 't', showSkip: false)),
      ));

      expect(find.text('تخطي'), findsNothing);
    });
  });
}
