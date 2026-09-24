// lib/shared/brand_backdrop.dart
//
// Shared brand treatment: a soft page background carrying a faint Islamic
// geometric motif, and the tinted icon badge used on course/home cards.
//
// Drawn with a CustomPainter rather than an image asset — the motif is pure
// geometry, so painting it costs nothing to download, scales to any density,
// and takes its colour from AppColors instead of being baked into a raster.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';

/// Page background: a near-white → primary50 vertical wash with an
/// eight-point-star lattice behind the header area only.
///
/// The pattern sits at 5% opacity over a very light wash, so text keeps its
/// contrast against the existing gray tokens; all cards paint solid white on
/// top regardless. The gradient is vertical and the motif is symmetric, so
/// nothing here depends on text direction.
class BrandBackdrop extends StatelessWidget {
  final Widget child;

  /// How far down the page the lattice fades out.
  final double patternHeight;

  const BrandBackdrop({
    super.key,
    required this.child,
    this.patternHeight = 260,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.white, AppColors.primary50],
          stops: [0.0, 0.85],
        ),
      ),
      child: Stack(
        children: [
          // Static: painted once and never repainted while the page scrolls.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: patternHeight,
            child: const RepaintBoundary(
              child: CustomPaint(
                painter: _ArabesquePainter(),
                child: SizedBox.expand(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A lattice of eight-point stars (two squares rotated 45° — the رُبع الحزب
/// motif), fading out toward the bottom of its box.
class _ArabesquePainter extends CustomPainter {
  const _ArabesquePainter();

  /// Well under the 6–8% ceiling: the motif should register as texture, never
  /// as content competing with the text above it.
  static const double _opacity = 0.05;
  static const double _tile = 64;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.brandPrimary.withOpacity(_opacity);

    // Fade the lattice out before it meets the page content.
    canvas.saveLayer(Offset.zero & size, Paint());

    for (double y = _tile / 2; y < size.height + _tile; y += _tile) {
      for (double x = _tile / 2; x < size.width + _tile; x += _tile) {
        _star(canvas, Offset(x, y), _tile * 0.34, paint);
      }
    }

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.transparent],
        ).createShader(Offset.zero & size),
    );

    canvas.restore();
  }

  /// Eight-point star: a square and the same square rotated 45°.
  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    for (final rotation in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rotation + i * math.pi / 2;
        final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The tinted square-ish badge that replaces the flat solid circles behind
/// subject icons on the course and home cards.
class BrandIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  /// Use the secondary ramp for non-subject icons (e.g. utility rows).
  final bool secondary;

  const BrandIconBadge({
    super.key,
    required this.icon,
    this.size = 48,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = secondary ? AppColors.secondary50 : AppColors.primary50;
    final border = secondary ? AppColors.secondary100 : AppColors.primary100;
    final glyph = secondary ? AppColors.brandSecondary : AppColors.brandPrimary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: border),
      ),
      child: Icon(icon, color: glyph, size: size * 0.5),
    );
  }
}
