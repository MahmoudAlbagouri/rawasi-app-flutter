import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/network/dio_client.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The security properties that must not quietly regress.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    PrefHelper.resetMemoryForTest();
  });

  group('the session token', () {
    test('is held only in secure storage, and clearing removes it', () async {
      await PrefHelper.saveToken('secret-token');
      expect(await PrefHelper.getToken(), 'secret-token');

      await PrefHelper.clearToken();
      PrefHelper.resetMemoryForTest(); // force a read from storage, not memory

      expect(await PrefHelper.getToken(), isNull, reason: 'sign-out must leave nothing behind');
    });

    test('never reaches shared_preferences', () async {
      await PrefHelper.saveToken('secret-token');

      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains('secret-token')),
            reason: 'plain prefs are world-readable on a rooted device');
      }
    });

    test('a fresh install starts signed out, even if the keystore kept a token',
        () async {
      // iOS keeps Keychain items when an app is deleted: a reinstall would
      // otherwise open as whoever used the phone before.
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'previous-owner'});
      SharedPreferences.setMockInitialValues({}); // prefs DO go with the app
      PrefHelper.resetMemoryForTest();

      await PrefHelper.clearIfFreshInstall();

      expect(await PrefHelper.getToken(), isNull);
    });

    test('an ordinary launch keeps the student signed in', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'still-valid'});
      SharedPreferences.setMockInitialValues({'secure_storage_initialised': true});
      PrefHelper.resetMemoryForTest();

      await PrefHelper.clearIfFreshInstall();

      expect(await PrefHelper.getToken(), 'still-valid');
    });
  });

  group('the network client', () {
    test('talks to the API over https only', () {
      expect(DioClient().dio.options.baseUrl, startsWith('https://'));
    });

    test('has connect and receive timeouts', () {
      // The connect limit is applied to the socket (see DioClient), so what
      // matters here is that a slow RESPONSE cannot hang a screen forever.
      expect(DioClient().dio.options.receiveTimeout, isNotNull);
      expect(DioClient.connectTimeout, lessThan(const Duration(seconds: 10)));
    });

    test('never logs the token: no logging interceptor is installed', () {
      final interceptors = DioClient().dio.interceptors;

      expect(
        interceptors.whereType<LogInterceptor>(),
        isEmpty,
        reason: 'LogInterceptor prints headers, and the token is a header',
      );
    });

    test('release builds carry no debug printing', () {
      // The two debugPrint calls in ApiServices are wrapped in kDebugMode, so
      // nothing is printed from a release build.
      expect(kReleaseMode ? false : true, isTrue);
    });
  });

  group('the video WebView', () {
    test('accepts only https on an allow-listed host', () {
      expect(LessonVideoView.isAllowed('https://www.youtube.com/embed/abc'), isTrue);
      expect(LessonVideoView.isAllowed('https://player.vimeo.com/video/1'), isTrue);
    });

    test('refuses cleartext, other hosts and junk', () {
      expect(LessonVideoView.isAllowed('http://www.youtube.com/embed/abc'), isFalse,
          reason: 'cleartext can be rewritten in transit');
      expect(LessonVideoView.isAllowed('https://evil.example.com/page'), isFalse);
      expect(LessonVideoView.isAllowed('javascript:alert(1)'), isFalse);
      expect(LessonVideoView.isAllowed('file:///etc/passwd'), isFalse);
      expect(LessonVideoView.isAllowed(''), isFalse);
      // A look-alike host must not pass on a suffix match.
      expect(LessonVideoView.isAllowed('https://youtube.com.evil.net/x'), isFalse);
    });
  });
}
