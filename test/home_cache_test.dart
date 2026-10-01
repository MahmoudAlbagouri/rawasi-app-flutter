import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';

/// The home cache across an auth change.
///
/// THE BUG: HomeRepo kept a static 90-second cache keyed on time alone. A
/// student who opened home while signed out had `HomeData.signedOut()` cached;
/// logging in within the next 90 seconds returned that stale snapshot, so home
/// rendered as a guest until they pulled to refresh. The token was always
/// saved correctly — the cache was answering for the wrong user.
///
/// The cache is now keyed on the auth token as well as time, which covers
/// signing in, signing out, and switching between students in one mechanism.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// flutter_secure_storage has no platform implementation under test, so
  /// stand one up in memory. This is the store the cache key reads from.
  late Map<String, String> storage;

  setUp(() {
    storage = {};
    HomeRepo.invalidate();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? const {};
        final key = args['key'] as String?;

        switch (call.method) {
          case 'write':
            storage[key!] = args['value'] as String;
            return null;
          case 'read':
            return storage[key];
          case 'delete':
            storage.remove(key);
            return null;
          case 'deleteAll':
            storage.clear();
            return null;
          case 'readAll':
            return storage;
          default:
            return null;
        }
      },
    );
  });

  tearDown(HomeRepo.invalidate);

  group('signed-out snapshot', () {
    test('is returned while still signed out', () async {
      final first = await HomeRepo().load();
      final second = await HomeRepo().load();

      expect(first.isSignedIn, isFalse);
      // Same cached instance — the cache is doing its job here.
      expect(identical(first, second), isTrue);
    });

    test('is NOT returned once a token exists', () async {
      // Exactly the reported sequence: guest home, then log in, then home is
      // rebuilt by pushAndRemoveUntil — all well inside the 90-second window.
      final guest = await HomeRepo().load();
      expect(guest.isSignedIn, isFalse);

      await PrefHelper.saveToken('a-real-token');

      final afterLogin = await HomeRepo().load();

      expect(
        identical(afterLogin, guest),
        isFalse,
        reason: 'the stale guest snapshot was served after login',
      );
      expect(afterLogin.isSignedIn, isTrue);
    });
  });

  group('signing out', () {
    test('does not leave the previous student cached', () async {
      await PrefHelper.saveToken('student-a');
      final signedIn = await HomeRepo().load();
      expect(signedIn.isSignedIn, isTrue);

      await PrefHelper.clearToken();

      final afterLogout = await HomeRepo().load();

      expect(afterLogout.isSignedIn, isFalse);
      expect(identical(afterLogout, signedIn), isFalse);
    });
  });

  group('switching students', () {
    test('student B never sees student A\'s cached load', () async {
      await PrefHelper.saveToken('student-a');
      final a = await HomeRepo().load();

      await PrefHelper.saveToken('student-b');
      final b = await HomeRepo().load();

      expect(
        identical(a, b),
        isFalse,
        reason: "student B was served student A's home data",
      );
    });
  });

  group('invalidate()', () {
    test('clears the snapshot and its owner', () async {
      final first = await HomeRepo().load();
      HomeRepo.invalidate();
      final second = await HomeRepo().load();

      expect(identical(first, second), isFalse);
    });
  });

  group('freshness', () {
    test('a stale snapshot is not reused even for the same token', () {
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

    test('a just-loaded snapshot is fresh', () {
      expect(HomeData.signedOut().isFresh, isTrue);
    });
  });
}
