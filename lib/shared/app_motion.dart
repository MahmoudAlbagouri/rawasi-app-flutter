// lib/shared/app_motion.dart
//
// The app's motion system: how screens arrive, how tabs switch, how a card
// answers a finger, and how a figure lands. Every screen uses these, so the
// whole app moves one way instead of each screen inventing its own.
//
// THE RULES (kept deliberately small):
//   - Short and decelerating. Arrivals 220–300 ms on Curves.easeOutCubic, so
//     motion explains where something came from and is then out of the way.
//   - Direction follows reading direction. "Forward" in Arabic is towards the
//     left, so a pushed screen slides in from the left, not the right.
//   - Nothing loops here. The one ambient, continuous motion in the app is the
//     BrandBackdrop behind the general screens, and it is paused whenever it
//     cannot be seen.
//   - "Reduce motion" turns every one of these into an instant change.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

/// Durations and the curve shared by every transition in the app.
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration tabSwitch = Duration(milliseconds: 240);
  static const Curve curve = Curves.easeOutCubic;

  /// The page transitions for the whole app (MaterialApp theme).
  ///
  /// iOS keeps the native Cupertino transition: students there expect the
  /// edge-swipe to go back, and a custom builder would lose that gesture.
  static const PageTransitionsTheme pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: SharedAxisPageTransitionsBuilder(),
      TargetPlatform.linux: SharedAxisPageTransitionsBuilder(),
      TargetPlatform.fuchsia: SharedAxisPageTransitionsBuilder(),
    },
  );

  /// Count-up figures are off under `flutter test`, where a number that is
  /// still counting would read as a wrong number to every existing test that
  /// checks a figure after a single pump. A test that wants to see it turns
  /// it on.
  @visibleForTesting
  static bool countUp =
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');
}

/// A pushed screen slides a short way in from the reading direction while
/// fading up; the screen it covers drifts a little the other way. A gentle
/// "shared axis" rather than a full-width slide.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (motionReduced(context)) return child;

    // The direction a new screen arrives FROM: the right in LTR (+1), the
    // left in RTL (-1). The screen it covers drifts the opposite way.
    final forward = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;

    final incoming = CurvedAnimation(
      parent: animation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: Offset(-0.06 * forward, 0),
      ).animate(outgoing),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.08 * forward, 0),
          end: Offset.zero,
        ).animate(incoming),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.7, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Switching tabs is not "going deeper", so it does not slide: the new tab
/// fades through and settles from 98.5% scale. Used by the bottom bar.
class TabSwitchRoute<T> extends PageRouteBuilder<T> {
  TabSwitchRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: AppMotion.tabSwitch,
        reverseTransitionDuration: AppMotion.quick,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) {
          if (motionReduced(context)) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.curve,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
}

/// A card or row that answers the finger: it settles in slightly while held
/// and springs back on release.
///
/// Built on a raw pointer Listener, so it never competes with the child's own
/// InkWell / GestureDetector, which still decides what a tap DOES. A finger
/// that starts to scroll releases the press at once, so scrolling a list never
/// makes the cards under it pulse.
class Pressable extends StatefulWidget {
  final Widget child;

  /// How far the card settles while held. 0.97 is felt, not seen.
  final double pressedScale;

  final bool enabled;

  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.enabled = true,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  Offset? _downAt;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || motionReduced(context)) return widget.child;

    return Listener(
      onPointerDown: (e) {
        _downAt = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_downAt != null && (e.position - _downAt!).distance > kTouchSlop) {
          _downAt = null;
          _set(false);
        }
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: _pressed ? const Duration(milliseconds: 90) : AppMotion.quick,
        curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// A figure that counts up from zero the first time it is shown, then lands
/// on EXACTLY [finalText] — the real formatter's output, so the settled value
/// is identical to what the screen printed before (e.g. "42.5%").
///
/// [during] formats the in-between whole numbers ("0%", "17%", …).
class CountUp extends StatelessWidget {
  final double value;
  final String finalText;
  final String Function(int value) during;
  final Widget Function(String text) builder;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    required this.finalText,
    required this.during,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    if (!AppMotion.countUp || motionReduced(context) || value <= 0) {
      return builder(finalText);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: AppMotion.curve,
      builder: (context, v, _) =>
          builder(v >= value ? finalText : during(v.round())),
    );
  }
}
