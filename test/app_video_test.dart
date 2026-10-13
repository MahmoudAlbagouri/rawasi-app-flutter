import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/contact/data/app_videos_repo.dart';
import 'package:rawasi_app_n/features/contact/views/intro_video_view.dart';
import 'package:rawasi_app_n/features/contact/widgets/youtube_embed.dart';

/// «كيف يعمل التطبيق؟» plays the walkthrough an admin pasted on the dashboard's
/// hero screen. The id below is the link from that screen.
void main() {
  const adminId = 'v-bcIfQzHFE'; // https://www.youtube.com/watch?v=v-bcIfQzHFE

  Map<String, dynamic> envelope(Object? walkthrough) => {
        'success': true,
        'data': {'walkthrough': walkthrough},
        'addtionalData': null,
        'message': 'تم',
      };

  group('AppVideo', () {
    test('reads the id the dashboard link produced', () {
      final video = AppVideo.tryParse({'id': adminId});

      expect(video, isNotNull);
      expect(video!.id, adminId);
      expect(video.watchUrl, 'https://www.youtube.com/watch?v=v-bcIfQzHFE');
      expect(
        video.embedUrl,
        'https://www.youtube-nocookie.com/embed/v-bcIfQzHFE?rel=0&playsinline=1',
      );
    });

    test('builds every URL from the id, never from what the server sent', () {
      final video = AppVideo.tryParse({
        'id': adminId,
        'url': 'https://evil.example/phish',
        'embed_url': 'javascript:alert(1)',
      });

      expect(video!.watchUrl, contains('youtube.com/watch?v=$adminId'));
      expect(video.embedUrl, isNot(contains('evil')));
      expect(video.embedUrl, isNot(contains('javascript')));
    });

    test('refuses anything that is not an 11-character YouTube id', () {
      for (final bad in <Object?>[
        null,
        'short',
        'wayTooLongToBeAnId',
        'abc def ghij', // a space
        '"><script>x</script>', // markup
        'v-bcIfQzHF/', // a slash
        '',
        123,
      ]) {
        expect(AppVideo.tryParse({'id': bad}), isNull, reason: '$bad');
      }
      expect(AppVideo.tryParse(null), isNull);
      expect(AppVideo.tryParse('v-bcIfQzHFE'), isNull, reason: 'not a map');
      expect(AppVideo.tryParse(<String, dynamic>{}), isNull);
    });

    test('the public constructor refuses a bad id too', () {
      expect(() => AppVideo('nope'), throwsArgumentError);
      expect(AppVideo(adminId).id, adminId);
    });
  });

  group('AppVideosRepo.parse', () {
    test('a published walkthrough', () {
      expect(AppVideosRepo.parse(envelope({'id': adminId}))!.id, adminId);
    });

    test('null while no link has been set - the screen shows "coming soon"', () {
      expect(AppVideosRepo.parse(envelope(null)), isNull);
      expect(AppVideosRepo.parse({'success': true, 'data': {}}), isNull);
      expect(AppVideosRepo.parse({'success': true, 'data': null}), isNull);
    });

    test('an ApiError VALUE is rethrown, as ApiServices returns it', () {
      final error = ApiError(message: 'لا يوجد اتصال', isConnectivityIssue: true);

      expect(
        () => AppVideosRepo.parse(error),
        throwsA(isA<ApiError>().having((e) => e.message, 'message', 'لا يوجد اتصال')),
      );
    });

    test('success:false is an error whatever the status said', () {
      expect(
        () => AppVideosRepo.parse({'success': false, 'message': 'تعذّر'}),
        throwsA(isA<ApiError>().having((e) => e.message, 'message', 'تعذّر')),
      );
      expect(
        () => AppVideosRepo.parse({'success': false}),
        throwsA(isA<ApiError>()),
      );
    });

    test('a body that is not a map is an error, not "coming soon"', () {
      expect(() => AppVideosRepo.parse('oops'), throwsA(isA<ApiError>()));
      expect(() => AppVideosRepo.parse(null), throwsA(isA<ApiError>()));
    });

    test('fetchWalkthrough asks /app-videos', () async {
      String? asked;
      final repo = AppVideosRepo(get: (endpoint) async {
        asked = endpoint;
        return envelope({'id': adminId});
      });

      expect((await repo.fetchWalkthrough())!.id, adminId);
      expect(asked, '/app-videos');
    });
  });

  group('YouTubeEmbed page', () {
    final video = AppVideo(adminId);

    test('is one full-size iframe on the embed URL', () {
      final html = YouTubeEmbed.html(video);

      expect(RegExp('<iframe ').allMatches(html), hasLength(1));
      // The address is written into an attribute, so its & is escaped.
      expect(html, contains('src="${video.embedUrl.replaceAll('&', '&amp;')}"'));
      expect(html, contains('allowfullscreen'));
      // The reason for the wrapper: the iframe's request must carry a referrer.
      expect(html, contains('referrerpolicy="strict-origin-when-cross-origin"'));
    });

    test('carries no script of its own', () {
      expect(YouTubeEmbed.html(video), isNot(contains('<script')));
    });
  });

  group('YouTubeEmbed navigation', () {
    bool main(String url) =>
        YouTubeEmbed.allowsNavigation(url, isMainFrame: true);
    bool frame(String url) =>
        YouTubeEmbed.allowsNavigation(url, isMainFrame: false);

    test('the page itself may only be our own wrapper', () {
      expect(main('https://rawasi.info/'), isTrue);
      expect(main('https://rawasi.info'), isTrue);
      expect(main('about:blank'), isTrue);
    });

    test('the player cannot take the whole view to YouTube or anywhere else', () {
      expect(main('https://www.youtube.com/watch?v=v-bcIfQzHFE'), isFalse);
      expect(main('https://youtu.be/v-bcIfQzHFE'), isFalse);
      expect(main('https://rawasi.info/login'), isFalse);
      expect(main('https://evil.example/'), isFalse);
      expect(main('http://rawasi.info/'), isFalse);
    });

    test('frames inside it may load the allow-listed video hosts only', () {
      expect(frame('https://www.youtube-nocookie.com/embed/v-bcIfQzHFE'), isTrue);
      expect(frame('https://www.youtube.com/embed/v-bcIfQzHFE'), isTrue);
      expect(frame('https://evil.example/embed/x'), isFalse);
      expect(frame('http://www.youtube.com/embed/x'), isFalse);
      expect(frame('https://youtube.com.evil.net/x'), isFalse);
      expect(frame('javascript:alert(1)'), isFalse);
    });
  });

  group('IntroVideoView', () {
    Widget screen(AppVideosRepo repo) => MaterialApp(
          locale: const Locale('ar'),
          home: IntroVideoView(repo: repo),
        );

    testWidgets('shows "coming soon" until a link is set', (tester) async {
      await tester.pumpWidget(
        screen(AppVideosRepo(get: (_) async => envelope(null))),
      );
      await tester.pumpAndSettle();

      expect(find.text('الفيديو التعريفي قادم قريبًا'), findsOneWidget);
      // The support route is always there.
      expect(find.text('تواصل مع الدعم'), findsOneWidget);
    });

    testWidgets('shows a loading card while the answer is on its way',
        (tester) async {
      await tester.pumpWidget(
        screen(AppVideosRepo(get: (_) => Future.delayed(
              const Duration(seconds: 5),
              () => envelope(null),
            ))),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('الفيديو التعريفي قادم قريبًا'), findsNothing);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('الفيديو التعريفي قادم قريبًا'), findsOneWidget);
    });

    testWidgets('a failed request says so and retries - it is not "coming soon"',
        (tester) async {
      var calls = 0;
      final repo = AppVideosRepo(get: (_) async {
        calls++;
        return calls == 1
            ? ApiError(
                message: 'لا يوجد اتصال بالإنترنت',
                isConnectivityIssue: true,
              )
            : envelope(null);
      });

      await tester.pumpWidget(screen(repo));
      await tester.pumpAndSettle();

      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(find.text('الفيديو التعريفي قادم قريبًا'), findsNothing);

      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('الفيديو التعريفي قادم قريبًا'), findsOneWidget);
    });

    testWidgets('an unexpected failure gets a plain message', (tester) async {
      await tester.pumpWidget(
        screen(AppVideosRepo(get: (_) async => throw StateError('boom'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعذّر تحميل الفيديو. حاول مرة أخرى.'), findsOneWidget);
    });
  });
}
