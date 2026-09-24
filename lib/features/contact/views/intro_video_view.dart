// lib/features/contact/views/intro_video_view.dart
//
// "كيف يعمل التطبيق؟" — the introductory video, plus the route to support.
//
// OPEN ITEM: the video itself does not exist yet. Everything here hangs off
// AppConstants.introVideoUrl; while that is empty the screen shows an honest
// "coming soon" state and still offers the support route, so dropping the real
// link in later is a one-line change and needs no other edit.
//
// Streamed, never bundled: the existing LessonVideoView already plays remote
// URLs through webview_flutter, so this reuses it rather than adding a second
// player package and a large asset to the APK.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/constants/app_constants.dart';
import 'package:rawasi_app_n/features/contact/views/contact_view.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class IntroVideoView extends StatelessWidget {
  const IntroVideoView({super.key});

  static const String title = 'كيف يعمل التطبيق؟';

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
          title,
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
              if (AppConstants.hasIntroVideo)
                _VideoCard(url: AppConstants.introVideoUrl)
              else
                _ComingSoonCard(),
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
}

class _VideoCard extends StatelessWidget {
  final String url;
  const _VideoCard({required this.url});

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
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LessonVideoView(videoUrl: url),
          ),
        ),
      ],
    );
  }
}

/// Shown until the real URL is set. Says so plainly rather than pretending a
/// player failed to load.
class _ComingSoonCard extends StatelessWidget {
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
