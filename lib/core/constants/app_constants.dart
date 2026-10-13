class AppConstants {
  static const int animationDuration = 300; // بالملي ثانية
  static const String appName = 'تطبيق رواسي';

  // The «كيف يعمل التطبيق؟» video is NOT a constant any more: an admin pastes its
  // link on the dashboard's hero screen and the app reads it from
  // GET /app-videos (see AppVideosRepo), so changing it needs no new build.

  /// The old "الدرس التمهيدي" videos, kept here so the home redesign did not
  /// throw them away.
  ///
  /// These were hardcoded in home_view and played through a DayCard row that
  /// the new layout removes. They are DIFFERENT content from the app
  /// walkthrough - an introductory lesson about the programme, not a tour of the
  /// app and its support channel - so they are deliberately NOT wired into it.
  /// Nothing references them today; point a surface at them (or delete them)
  /// once it is clear where the content belongs.
  static const String orientationVideoGuest =
      'https://player.mediadelivery.net/embed/556412/ac68484d-d8bb-420e-8119-76deaccb7b75';
  static const String orientationVideoStudent =
      'https://player.mediadelivery.net/embed/556412/846d3a20-fd96-4560-97ea-ac097c4d2256';
}
