// lib/features/lesson/views/lesson_video_view.dart
//
// A simple embedded-video player, used for the static intro video on Home.

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LessonVideoView extends StatefulWidget {
  final String videoUrl;

  const LessonVideoView({super.key, required this.videoUrl});

  @override
  State<LessonVideoView> createState() => _LessonVideoViewState();
}

class _LessonVideoViewState extends State<LessonVideoView> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(widget.videoUrl.trim()));
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
                child: WebViewWidget(controller: _webViewController),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
