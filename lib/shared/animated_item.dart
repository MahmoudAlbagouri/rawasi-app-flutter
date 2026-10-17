// lib/shared/animated_item.dart
//
// The app's one entrance animation: a short fade + slide as a card arrives.
// Home started it; the courses, lessons, library, statistics and profile
// screens use the same one, so every screen moves the same way.

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

/// Entrance stagger. Extended rather than replaced — this is the app's one
/// entrance animation.
class AnimatedItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedItem> createState() => AnimatedItemState();
}

class AnimatedItemState extends State<AnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion: show the settled state immediately, no slide, no fade.
    if (motionReduced(context)) {
      if (!_controller.isCompleted) _controller.value = 1;
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

/// Staggers the FIRST SCREENFUL of a list in, once.
///
/// A ListView rebuilds rows as they scroll back into view, and animating every
/// rebuild would make a list "re-arrive" each time the student scrolls up.
/// So only rows built in the first moments after the list first appears, and
/// only the first few of them, get the entrance; everything after is plain.
///
/// Keep one per screen State (`final _stagger = StaggerOnce();`).
class StaggerOnce {
  StaggerOnce({
    this.maxItems = 8,
    this.window = const Duration(milliseconds: 900),
  });

  final int maxItems;
  final Duration window;

  Stopwatch? _clock;

  Widget wrap(int index, Widget child) {
    final clock = _clock ??= (Stopwatch()..start());

    if (index >= maxItems || clock.elapsed > window) return child;

    return AnimatedItem(
      delay: Duration(milliseconds: 40 + index * 55),
      child: child,
    );
  }
}
