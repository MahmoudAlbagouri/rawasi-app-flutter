class AppConstants {
  static const int animationDuration =
      300; // بالملي ثانية
  static const String appName =
      'تطبيق رواسي';

  /// The introductory "how the app works" video.
  ///
  /// OPEN ITEM: not produced yet. Leave it empty and every surface degrades
  /// gracefully - the home card hides itself and IntroVideoView shows a
  /// "coming soon" state - so publishing the real link means editing this one
  /// line and nothing else. Stream it (a hosted URL); do not bundle the file.
  static const String introVideoUrl = '';

  static bool get hasIntroVideo => introVideoUrl.trim().isNotEmpty;
}
