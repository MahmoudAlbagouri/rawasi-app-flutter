// lib/shared/celebration_burst.dart
//
// A single, short celebration for finishing a lesson: small pieces in the
// app's own colours burst out from behind the success icon and settle away,
// while the icon scales in. It plays once and never loops.
//
// In the brand, not a party: the palette is AppColors only (brand blue, its
// light tint, the success green and the brand gold), the pieces include the
// same eight-point star the page backdrop uses, and it is over in about a
// second and a half. With "reduce motion" on, the icon is simply shown.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

class CelebrationBurst extends StatefulWidget {
  /// The icon at the centre of the burst.
  final Widget child;

  /// The square the pieces travel within.
  final double size;

  const CelebrationBurst({super.key, required this.child, this.size = 220});

  /// The colours a piece can take — brand tokens only.
  static const List<Color> palette = [
    AppColors.brandPrimary,
    AppColors.primary300,
    AppColors.success500,
    AppColors.brandWarning,
  ];

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final Animation<double> _iconScale = Tween<double>(begin: 0.55, end: 1)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.55, curve: Curves.elasticOut),
        ),
      );

  // Fixed seed: the same burst every time, never a random-looking glitch.
  late final List<_Piece> _pieces = _Piece.scatter(math.Random(11), count: 22);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (motionReduced(context)) {
      _controller.value = 1; // settled: icon at full size, pieces gone
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.62,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _BurstPainter(_controller, _pieces)),
            ),
          ),
          ScaleTransition(scale: _iconScale, child: widget.child),
        ],
      ),
    );
  }
}

class _Piece {
  final double angle;
  final double distance;
  final double size;
  final double spin;
  final Color color;
  final bool star;

  const _Piece(
    this.angle,
    this.distance,
    this.size,
    this.spin,
    this.color,
    this.star,
  );

  static List<_Piece> scatter(math.Random rnd, {required int count}) {
    return List.generate(count, (i) {
      // Evenly round the circle, with a little jitter so it is not a ring.
      final angle = (i / count) * 2 * math.pi + (rnd.nextDouble() - 0.5) * 0.35;
      return _Piece(
        angle,
        0.55 + rnd.nextDouble() * 0.45, // fraction of the radius it reaches
        3.0 + rnd.nextDouble() * 3.5,
        (rnd.nextDouble() - 0.5) * 6,
        CelebrationBurst.palette[i % CelebrationBurst.palette.length],
        i % 3 == 0,
      );
    });
  }
}

class _BurstPainter extends CustomPainter {
  final Animation<double> progress;
  final List<_Piece> pieces;

  _BurstPainter(this.progress, this.pieces) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return; // nothing before the start or after the end

    final centre = size.center(Offset.zero);
    final radius = size.width * 0.46;
    final travel = Curves.easeOutCubic.transform(t);
    // Fully visible for most of the flight, then gone.
    final opacity = t < 0.55 ? 1.0 : (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0);

    for (final p in pieces) {
      final d = radius * p.distance * travel;
      final fall = 18 * t * t; // a touch of gravity
      final pos =
          centre +
          Offset(math.cos(p.angle) * d, math.sin(p.angle) * d * 0.72 + fall);
      final paint = Paint()..color = p.color.withOpacity(opacity * 0.9);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.star) {
        _star(canvas, p.size * 1.15, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.6,
              height: p.size,
            ),
            Radius.circular(p.size / 2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  /// The backdrop's eight-point star, filled.
  void _star(Canvas canvas, double r, Paint paint) {
    for (final rotation in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rotation + i * math.pi / 2;
        final pt = Offset(r * math.cos(a), r * math.sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => false; // repaints via [progress]
}
