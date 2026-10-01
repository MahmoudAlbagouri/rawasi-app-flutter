import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/home/data/home_data.dart';

/// THE BUG: for about a second after logging in, home rendered as a guest —
/// "مرحباً بك، ضيف" and the "ابدأ رحلتك مع رواسي" sign-up card — then corrected
/// itself.
///
/// It had nothing to do with the token, which was saved before home was ever
/// built. Home simply had two states where it needed three. It did
///
///     final data = snapshot.data ?? HomeData.signedOut();
///
/// so for as long as the four requests were in flight, "no profile yet" and
/// "this person is a guest" were the same value. Pull-to-refresh hit it too: a
/// FutureBuilder drops its snapshot when its future is replaced, so refreshing
/// a logged-in home briefly replaced it with the guest screen it was
/// refreshing.
///
/// The third state is `isLoading`, and [HomeData.placeholder] is the rule that
/// picks between the three.
void main() {
  HomeData signedInLoad() => HomeData(
        isSignedIn: true,
        profile: null,
        stats: null,
        courses: null,
        library: null,
        loadedAt: DateTime.now(),
      );

  group('before the token read answers', () {
    test('nothing is claimed about who the student is', () {
      final data = HomeData.placeholder(last: null, hasSession: null);

      expect(data.isLoading, isTrue);
      expect(
        data.isSignedIn,
        isTrue,
        reason: 'isSignedIn gates the sign-up card, which must stay hidden '
            'while we do not know',
      );
    });

    test('a guest snapshot from before a login is NOT reused', () {
      // The exact sequence: home viewed as a guest, student logs in, home is
      // rebuilt. HomeRepo still holds the guest load, and showing it is the
      // flash.
      final data = HomeData.placeholder(
        last: HomeData.signedOut(),
        hasSession: null,
      );

      expect(data.isLoading, isTrue);
      expect(data.profile, isNull);
    });
  });

  group('once the token read answers', () {
    test('a token with a stale guest snapshot still gives the loader', () {
      final data = HomeData.placeholder(
        last: HomeData.signedOut(),
        hasSession: true,
      );

      expect(data.isLoading, isTrue, reason: 'this is the reported bug');
    });

    test('no token gives the guest screen, and only then', () {
      final data = HomeData.placeholder(last: null, hasSession: false);

      expect(data.isSignedIn, isFalse);
      expect(data.isLoading, isFalse);
    });

    test('a signed-out snapshot is reused once there is genuinely no token', () {
      final guest = HomeData.signedOut();
      final data = HomeData.placeholder(last: guest, hasSession: false);

      expect(identical(data, guest), isTrue);
    });
  });

  group('refreshing an already-loaded home', () {
    test('keeps the screen it is refreshing instead of blanking it', () {
      final loaded = signedInLoad();
      final data = HomeData.placeholder(last: loaded, hasSession: true);

      expect(identical(data, loaded), isTrue);
      expect(data.isLoading, isFalse);
    });

    test('a snapshot from the student who just signed OUT is dropped', () {
      final data = HomeData.placeholder(
        last: signedInLoad(),
        hasSession: false,
      );

      expect(data.isSignedIn, isFalse);
      expect(identical(data, signedInLoad()), isFalse);
    });
  });

  group('the loading snapshot itself', () {
    test('carries no data to render', () {
      final data = HomeData.loading();

      expect(data.profile, isNull);
      expect(data.stats, isNull);
      expect(data.courses, isNull);
      expect(data.library, isNull);
    });

    test('a real load is never marked as loading', () {
      expect(HomeData.signedOut().isLoading, isFalse);
      expect(signedInLoad().isLoading, isFalse);
    });
  });
}
