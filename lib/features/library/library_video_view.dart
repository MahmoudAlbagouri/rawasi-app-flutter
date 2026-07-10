// lib/features/library/views/library_video_view.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/data/library_video.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LibraryVideoView extends StatefulWidget {
  final LibraryVideo video;

  const LibraryVideoView({super.key, required this.video});

  @override
  State<LibraryVideoView> createState() => _LibraryVideoViewState();
}

class _LibraryVideoViewState extends State<LibraryVideoView>
    with SingleTickerProviderStateMixin {
  late WebViewController _webViewController;
  bool _webViewLoaded = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    if (widget.video.videoUrl.isNotEmpty) {
      _webViewController.loadRequest(Uri.parse(widget.video.videoUrl));
      _webViewLoaded = true;
    }

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _webViewController.clearCache();
    _fadeController.dispose();
    super.dispose();
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
          title: Text(
            widget.video.title,
            style: const TextStyle(color: AppColors.gray800, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // مشغّل الفيديو
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            WebViewWidget(controller: _webViewController),
                            if (!_webViewLoaded)
                              Container(
                                color: Colors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '00:00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Gap(24),
                    // بطاقة المعلومات
                    _buildLessonCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: TextStyle(
              color: AppColors.brandSecondary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8),
          Text(
            widget.video.description,
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
