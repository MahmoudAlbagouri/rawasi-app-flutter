// lib/features/lesson/views/lesson_video_view.dart
//
// A simple embedded-video player, used for the static intro video on Home.
//
// LOCKED DOWN. A WebView is the widest attack surface in the app, so this one
// only ever loads an https URL on an allow-listed host, and refuses to follow
// a navigation away from those hosts — a redirect cannot walk it onto an
// arbitrary page. JavaScript stays on because the video players need it; it
// is bounded by the allow-list rather than by trusting the page. The app
// never puts a token in these URLs, so nothing is leaked by loading one.

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LessonVideoView extends StatefulWidget {
  final String videoUrl;

  const LessonVideoView({super.key, required this.videoUrl});

  /// Hosts this player may open. Video embeds only — nothing that could carry
  /// a session or a form.
  static const Set<String> allowedHosts = {
    'youtube.com',
    'www.youtube.com',
    'youtu.be',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
    'player.vimeo.com',
    'vimeo.com',
    'drive.google.com',
    'rawasi.info',
    'www.rawasi.info',
  };

  /// https, and a host on the list. Anything else is not loaded at all.
  @visibleForTesting
  static bool isAllowed(String url) {
    final uri = Uri.tryParse(url.trim());

    return uri != null &&
        uri.scheme == 'https' &&
        allowedHosts.contains(uri.host.toLowerCase());
  }

  @override
  State<LessonVideoView> createState() => _LessonVideoViewState();
}

class _LessonVideoViewState extends State<LessonVideoView> {
  late final WebViewController _webViewController;

  /// The URL was not https on an allow-listed host, so nothing was loaded.
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _blocked = !LessonVideoView.isAllowed(widget.videoUrl);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          // A page may redirect; it may not redirect somewhere else.
          onNavigationRequest: (request) =>
              LessonVideoView.isAllowed(request.url)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      );

    if (!_blocked) {
      _webViewController.loadRequest(Uri.parse(widget.videoUrl.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الدرس التمهيدي',
            style: TextStyle(color: AppColors.gray800, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: _blocked
                    // Nothing was loaded, so say so rather than showing a
                    // blank black box the student will tap at.
                    ? Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          'تعذّر تشغيل الفيديو — الرابط غير صالح.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.gray700),
                        ),
                      )
                    : WebViewWidget(controller: _webViewController),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
