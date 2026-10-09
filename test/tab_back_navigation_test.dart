import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/root.dart';

/// THE BUG: tab switches use pushReplacement (CustomBottomNavBar.onTap), so a
/// tab reached that way is very often the ONLY route on the navigator stack —
/// and a plain system back press on an app's single remaining route hands
/// straight to the OS, closing the app. Reported as "back from any inner page
/// exits immediately".
///
/// THE FIX: back on a non-Home tab with nothing below it goes to Home first;
/// back on Home with nothing below it exits, same as before. Back on a tab
/// that WAS reached by an ordinary push (something real underneath) just pops
/// to that normally, with no detour through a second Home.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // flutter_secure_storage talks over a platform channel that does not
    // exist in a widget test. "No token" is enough for HomeView's own load to
    // resolve to a quick, networkless signed-out state.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  Widget app(Widget home) =>
      MaterialApp(locale: const Locale('ar'), home: home);

  /// A stand-in tab-root screen: just enough of the real shape
  /// (CustomBottomNavBar as `bottomNavigationBar`) for the back-button logic
  /// to see, without pulling in a whole real screen's own network calls.
  Widget tabRoot(NavTab tab) => Scaffold(
    appBar: AppBar(title: Text(tab.label)),
    body: Center(child: Text('${tab.label} body')),
    bottomNavigationBar: CustomBottomNavBar(current: tab),
  );

  int currentBottomNavIndex(WidgetTester tester) =>
      tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      ).currentIndex;

  group('back on a tab reached via the bottom nav (pushReplacement)', () {
    testWidgets(
      'from a non-Home tab with nothing below it, goes to Home instead of exiting',
      (tester) async {
        await tester.pumpWidget(app(tabRoot(NavTab.courses)));
        expect(Navigator.canPop(tester.element(find.text('المواد body'))), isFalse);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        // Home, not a closed app and not the courses tab still showing.
        expect(find.text('المواد body'), findsNothing);
        expect(currentBottomNavIndex(tester), NavTab.home.index);
      },
    );

    testWidgets(
      'from Home itself with nothing below it, Flutter is left to exit — not redirected again',
      (tester) async {
        await tester.pumpWidget(app(tabRoot(NavTab.home)));

        final popScope = tester.widget<PopScope<Object?>>(
          find.byWidgetPredicate((w) => w is PopScope<Object?>),
        );

        // THE OTHER HALF OF THE SPEC: "if already on Home, press back again
        // -> exit the app." canPop: true here is what lets Flutter hand the
        // press to the OS instead of looping back to another Home.
        expect(
          popScope.canPop,
          isTrue,
          reason: 'Home is where back is allowed to actually exit',
        );
      },
    );

    testWidgets('pressing back twice from a non-Home tab lands on Home, then exits — never a third screen', (
      tester,
    ) async {
      await tester.pumpWidget(app(tabRoot(NavTab.stats)));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(currentBottomNavIndex(tester), NavTab.home.index);

      // Second press: now ON Home with nothing below it — canPop must be
      // true, the same case asserted explicitly above.
      final popScope = tester.widget<PopScope<Object?>>(
        find.byWidgetPredicate((w) => w is PopScope<Object?>),
      );
      expect(popScope.canPop, isTrue);
    });
  });

  group('back on a tab reached via an ordinary push (something real below it)', () {
    testWidgets('pops to what is actually underneath, not a fresh Home', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => tabRoot(NavTab.courses)),
                  ),
                  child: const Text('open courses from home content'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open courses from home content'));
      await tester.pumpAndSettle();
      expect(find.text('المواد body'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Back to the ACTUAL screen underneath, not a second, unrelated Home.
      expect(find.text('open courses from home content'), findsOneWidget);
      expect(find.text('المواد body'), findsNothing);
    });

    testWidgets('canPop is true here, because something real IS below it', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => tabRoot(NavTab.library)),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope<Object?>>(
        find.byWidgetPredicate((w) => w is PopScope<Object?>),
      );
      expect(popScope.canPop, isTrue);
    });
  });

  group('deeper pages pushed on top of a tab root', () {
    testWidgets('pop fine among themselves, unaffected by the tab-root guard', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('inner page'),
              ),
              body: const Text('inner page body'),
            ),
          ),
        ),
      );

      // This inner page is the whole stack (no tab root below it in this
      // test) — the point here is just that an ordinary AppBar back press on
      // a normal page is untouched by CustomBottomNavBar's PopScope, which
      // only ever wraps the five actual tab roots.
      expect(find.byType(PopScope), findsNothing);
    });
  });
}
