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

  /// The old "الدرس التمهيدي" videos, kept here so the home redesign did not
  /// throw them away.
  ///
  /// These were hardcoded in home_view and played through a DayCard row that
  /// the new layout removes. They are DIFFERENT content from
  /// [introVideoUrl] - an introductory lesson about the programme, not a
  /// walkthrough of the app and its support channel - so they are deliberately
  /// NOT wired into it. Nothing references them today; point a surface at them
  /// (or delete them) once it is clear where the content belongs.
  static const String orientationVideoGuest =
      'https://player.mediadelivery.net/embed/556412/ac68484d-d8bb-420e-8119-76deaccb7b75';
  static const String orientationVideoStudent =
      'https://player.mediadelivery.net/embed/556412/846d3a20-fd96-4560-97ea-ac097c4d2256';
}
