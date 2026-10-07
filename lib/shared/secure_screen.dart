// lib/shared/secure_screen.dart
//
// Blocks screenshots and screen recording while a sensitive screen is open.
//
// WHY. Passwords, OTP codes and payment receipts are on screen here. Android
// shows the app's own content in the task switcher and lets any screen
// recorder capture it; iOS allows screenshots and recording. Protection is
// turned on when the screen appears and off when it leaves, so the rest of
// the app still screenshots normally — students do share their progress.
//
// WHAT IT IS NOT. A determined attacker with the unlocked phone in hand can
// photograph it. This stops casual capture and, on Android, stops the OTP
// from sitting in the recent-apps preview.
//
// Mix into a State and the screen protects itself:
//
//     class _LoginViewState extends State<LoginView> with SecureScreen { ... }

import 'package:flutter/widgets.dart';
import 'package:screen_protector/screen_protector.dart';

mixin SecureScreen<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _protect();
  }

  @override
  void dispose() {
    _unprotect();
    super.dispose();
  }

  /// Every call is guarded: these are platform channels, they can fail (and
  /// simply do not exist on desktop or web), and a screen must still open if
  /// protection cannot be applied.
  Future<void> _protect() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      // Android only: blanks the app's thumbnail in the task switcher.
      await ScreenProtector.protectDataLeakageOn();
    } catch (_) {
      // Unsupported platform or a channel error — the screen still works.
    }
  }

  Future<void> _unprotect() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (_) {
      // Nothing to undo.
    }
  }
}
