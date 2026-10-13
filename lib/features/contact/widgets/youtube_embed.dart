// lib/features/contact/widgets/youtube_embed.dart
//
// An embedded YouTube player for «كيف يعمل التطبيق؟».
//
// WHY THE EXTRA PAGE. Loading the embed URL directly as the WebView's page
// sends no Referer, and YouTube answers a referrer-less embed with "error 153:
// video player configuration error". So the WebView loads a tiny page of our
// own - a single full-size iframe - served under an https origin, and the
// iframe's request then carries one.
//
// LOCKED DOWN, like every WebView in this app: the only page the WebView will
// ever show is that one, a frame inside it may only go to a host on
// LessonVideoView's allow-list (the one allow-list there is), and a tap on the
// YouTube logo or a related video cannot take the whole WebView off to
// youtube.com - it is simply refused. "Open in YouTube" is a separate button
// on the screen.

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/contact/data/app_videos_repo.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeEmbed extends StatefulWidget {
  final AppVideo video;

  const YouTubeEmbed({super.key, required this.video});

  /// The origin the wrapper page is served under. Any https origin satisfies
  /// YouTube; this is ours, and it is on the allow-list.
  static const String origin = 'https://rawasi.info/';

  /// The wrapper page. [AppVideo] only ever holds a validated 11-character id,
  /// so writing its URL into the markup cannot inject anything.
  @visibleForTesting
  static String html(AppVideo video) =>
      '<!doctype html><html><head>'
      '<meta name="viewport" content="width=device-width, initial-scale=1">'
      '<style>html,body{margin:0;height:100%;background:#000}'
      'iframe{position:absolute;inset:0;width:100%;height:100%;border:0}</style>'
      '</head><body>'
      '<iframe src="${video.embedUrl.replaceAll('&', '&amp;')}" title="شرح التطبيق" '
      'allow="autoplay; encrypted-media; picture-in-picture; fullscreen" '
      'allowfullscreen referrerpolicy="strict-origin-when-cross-origin">'
      '</iframe></body></html>';

  /// Whether the WebView may go to [url].
  ///
  /// The page itself (main frame) is only ever our own wrapper; anything the
  /// player tries to navigate the whole view to is refused. Frames inside it
  /// may load the allow-listed video hosts.
  @visibleForTesting
  static bool allowsNavigation(String url, {required bool isMainFrame}) {
    if (!isMainFrame) return LessonVideoView.isAllowed(url);

    if (url == 'about:blank') return true;

    final uri = Uri.tryParse(url);

    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == Uri.parse(origin).host &&
        (uri.path.isEmpty || uri.path == '/');
  }

  @override
  State<YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<YouTubeEmbed> {
  late final WebViewController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // the player needs it
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              YouTubeEmbed.allowsNavigation(
                request.url,
                isMainFrame: request.isMainFrame,
              )
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onWebResourceError: (error) {
            // Only the page itself: a failing frame shows YouTube's own message.
            if (error.isForMainFrame ?? false) {
              if (mounted) setState(() => _failed = true);
            }
          },
        ),
      )
      ..loadHtmlString(
        YouTubeEmbed.html(widget.video),
        baseUrl: YouTubeEmbed.origin,
      );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _failed
            ? Container(
                color: Colors.black12,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'تعذّر تشغيل الفيديو هنا. يمكنك فتحه في يوتيوب بالزر أدناه.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gray700),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
