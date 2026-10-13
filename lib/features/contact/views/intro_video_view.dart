// lib/features/contact/views/intro_video_view.dart
//
// "كيف يعمل التطبيق؟" — the introductory video, plus the route to support.
//
// The video is whatever an admin pasted on the dashboard's hero screen
// (GET /app-videos), so publishing or replacing it needs no new app build.
// Until a link is set the screen shows an honest "coming soon" state, and it
// always offers the support route underneath.
//
// Streamed from YouTube, never bundled: no player package and no large asset in
// the APK. The player is YouTubeEmbed, a locked-down WebView; "open in YouTube"
// is offered beside it because an in-app WebView has no reliable fullscreen.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/contact/data/app_videos_repo.dart';
import 'package:rawasi_app_n/features/contact/views/contact_view.dart';
import 'package:rawasi_app_n/features/contact/widgets/youtube_embed.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';
import 'package:url_launcher/url_launcher.dart';

class IntroVideoView extends StatefulWidget {
  /// [repo] exists so a test can supply the answer without a network.
  const IntroVideoView({super.key, this.repo});

  final AppVideosRepo? repo;

  static const String title = 'كيف يعمل التطبيق؟';

  @override
  State<IntroVideoView> createState() => _IntroVideoViewState();
}

class _IntroVideoViewState extends State<IntroVideoView> {
  late Future<AppVideo?> _video;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _video = (widget.repo ?? AppVideosRepo()).fetchWalkthrough();
  }

  void _retry() => setState(_load);

  /// No canLaunchUrl() first: on Android 11+ it answers from the manifest
  /// <queries> list and can say false for a target that launches fine.
  Future<void> _openInYouTube(AppVideo video) async {
    try {
      final launched = await launchUrl(
        Uri.parse(video.watchUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw Exception('not launched');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا يمكن فتح يوتيوب من هذا الجهاز'),
          backgroundColor: AppColors.error500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          IntroVideoView.title,
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<AppVideo?>(
                future: _video,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _LoadingCard();
                  }
                  if (snapshot.hasError) {
                    return _ErrorCard(
                      message: _messageFor(snapshot.error),
                      onRetry: _retry,
                    );
                  }

                  final video = snapshot.data;
                  if (video == null) return const _ComingSoonCard();

                  return _VideoCard(
                    video: video,
                    onOpenInYouTube: () => _openInYouTube(video),
                  );
                },
              ),
              const Gap(24),
              const CustomText(
                text: 'تحتاج مساعدة؟',
                color: AppColors.gray900,
                size: 17,
                weight: FontWeight.bold,
              ),
              const Gap(8),
              const CustomText(
                text:
                    'فريق الدعم متاح للرد على أسئلتك ومساعدتك في أي وقت عبر صفحة تواصل معنا.',
                color: AppColors.gray700,
                size: 14,
              ),
              const Gap(16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactView()),
                ),
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: const Text(
                  'تواصل مع الدعم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The server's / connectivity message when there is one (the offline text is
  /// already an honest one), a plain fallback otherwise.
  String _messageFor(Object? error) =>
      error is ApiError && error.message.trim().isNotEmpty
      ? error.message
      : 'تعذّر تحميل الفيديو. حاول مرة أخرى.';
}

class _VideoCard extends StatelessWidget {
  final AppVideo video;
  final VoidCallback onOpenInYouTube;

  const _VideoCard({required this.video, required this.onOpenInYouTube});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CustomText(
          text: 'شاهد الفيديو التعريفي',
          color: AppColors.gray900,
          size: 17,
          weight: FontWeight.bold,
        ),
        const Gap(12),
        YouTubeEmbed(video: video),
        const Gap(8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onOpenInYouTube,
            icon: const Icon(
              Icons.open_in_new,
              size: 18,
              color: AppColors.brandPrimary,
            ),
            label: const Text(
              'افتح الفيديو في يوتيوب',
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Same footprint as the player, so the screen does not jump when it arrives.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary100),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// The request itself failed - not the same thing as "no video yet".
class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 44,
            color: AppColors.brandPrimary,
          ),
          const Gap(12),
          CustomText(
            text: message,
            color: AppColors.gray900,
            size: 14,
            align: TextAlign.center,
          ),
          const Gap(12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

/// Shown until an admin sets the link. Says so plainly rather than pretending a
/// player failed to load.
class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.ondemand_video_outlined,
            size: 48,
            color: AppColors.brandPrimary,
          ),
          Gap(14),
          CustomText(
            text: 'الفيديو التعريفي قادم قريبًا',
            color: AppColors.gray900,
            size: 16,
            weight: FontWeight.bold,
            align: TextAlign.center,
          ),
          Gap(8),
          CustomText(
            text:
                'نعمل على إعداد شرح مبسّط لطريقة استخدام التطبيق. حتى ذلك الحين يسعدنا مساعدتك عبر الدعم.',
            color: AppColors.gray700,
            size: 14,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
