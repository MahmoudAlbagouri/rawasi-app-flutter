// lib/features/home/widgets/animated_item.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

/// Entrance stagger. Extended rather than replaced — this is the screen's one
/// animation system.
class AnimatedItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedItem({required this.child, required this.delay});

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
