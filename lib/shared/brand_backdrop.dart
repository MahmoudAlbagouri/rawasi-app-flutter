// lib/shared/brand_backdrop.dart
//
// Shared brand treatment: a soft page background carrying a faint Islamic
// geometric motif, and the tinted icon badge used on course/home cards.
//
// Drawn with a CustomPainter rather than an image asset — the motif is pure
// geometry, so painting it costs nothing to download, scales to any density,
// and takes its colour from AppColors instead of being baked into a raster.
//
// AMBIENT MOTION (2026-10-17). The lattice drifts very slowly — about one
// pixel a second, one tile a minute, a seamless loop because the pattern
// repeats every tile — and a soft brand-blue glow breathes in the top corner.
// It is meant to be felt rather than watched, on the general screens (home,
// subjects, library, statistics, profile); the question screen does not use
// this backdrop, so nothing moves while a student is reading a question.
//
// Kept cheap and polite:
//   - the lattice is still painted ONCE; the motion only moves that painted
//     layer, it never repaints the stars;
//   - a timer advances it ~15 times a second, not the display's 60–120 —
//     at a pixel a second, more frames would be invisible and cost battery;
//   - it stops when the screen is covered by another, when the app is in the
//     background, and entirely when the device asks to reduce motion.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/home_section.dart';

/// Page background: a near-white → primary50 vertical wash with an
/// eight-point-star lattice behind the header area only.
///
/// The pattern sits at 5% opacity over a very light wash, so text keeps its
/// contrast against the existing gray tokens; all cards paint solid white on
/// top regardless. The gradient is vertical and the motif is symmetric, so
/// nothing here depends on text direction.
class BrandBackdrop extends StatefulWidget {
  final Widget child;

  /// How far down the page the lattice fades out.
  final double patternHeight;

  const BrandBackdrop({
    super.key,
    required this.child,
    this.patternHeight = 260,
  });

  /// Whether the ambient motion may run at all.
  ///
  /// Off under `flutter test`: an endless animation would keep pumpAndSettle
  /// waiting forever. A test that wants to see the motion turns it on.
  @visibleForTesting
  static bool ambientMotion =
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  /// One tile of drift takes this long.
  static const Duration driftPeriod = Duration(seconds: 60);

  /// How often the motion advances.
  static const Duration frameInterval = Duration(milliseconds: 66);

  @override
  State<BrandBackdrop> createState() => _BrandBackdropState();
}

class _BrandBackdropState extends State<BrandBackdrop>
    with WidgetsBindingObserver {
  /// Seconds of ambient time, the one value the motion is drawn from.
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;

  bool _visible = true;
  bool _foreground = true;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // False while another screen covers this one: the navigator keeps it
    // alive but mutes it.
    _visible = TickerMode.of(context);
    _reducedMotion = motionReduced(context);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  /// Runs the clock exactly while the motion can be seen and is wanted.
  void _sync() {
    final run =
        BrandBackdrop.ambientMotion &&
        _visible &&
        _foreground &&
        !_reducedMotion;

    if (run && _timer == null) {
      _clock.start();
      _timer = Timer.periodic(BrandBackdrop.frameInterval, (_) {
        _seconds.value = _clock.elapsedMilliseconds / 1000;
      });
    } else if (!run && _timer != null) {
      _timer!.cancel();
      _timer = null;
      _clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _seconds.dispose();
    super.dispose();
  }

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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.patternHeight,
            child: IgnorePointer(child: _DriftingLattice(seconds: _seconds)),
          ),
          Positioned(
            top: -110,
            right: -90,
            child: IgnorePointer(child: _BreathingGlow(seconds: _seconds)),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// The lattice, fading out toward the bottom of its box, drifting one tile
/// diagonally per [BrandBackdrop.driftPeriod].
class _DriftingLattice extends StatelessWidget {
  final ValueListenable<double> seconds;

  const _DriftingLattice({required this.seconds});

  @override
  Widget build(BuildContext context) {
    const tile = _ArabesquePainter.tile;
    final period = BrandBackdrop.driftPeriod.inMilliseconds / 1000;

    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth + tile;
        final height = box.maxHeight + tile;

        return ClipRect(
          // The fade is anchored to the box, so it stays put while the
          // pattern moves underneath it.
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.transparent],
            ).createShader(rect),
            child: ValueListenableBuilder<double>(
              valueListenable: seconds,
              builder: (context, s, painted) {
                final p = (s % period) / period;
                return Transform.translate(
                  key: const ValueKey('brand-backdrop-lattice'),
                  offset: Offset(-p * tile, -p * tile),
                  child: painted,
                );
              },
              // One tile larger than the box, so the drift never shows an
              // edge; painted once and only ever moved.
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: const RepaintBoundary(
                  child: CustomPaint(
                    painter: _ArabesquePainter(),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A soft brand-blue light in the top corner, drifting and breathing slowly.
class _BreathingGlow extends StatelessWidget {
  final ValueListenable<double> seconds;

  const _BreathingGlow({required this.seconds});

  static const double size = 300;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: seconds,
      builder: (context, s, glow) {
        // Three unrelated periods, so the path never visibly repeats.
        final dx = math.sin(2 * math.pi * s / 26) * 26;
        final dy = math.cos(2 * math.pi * s / 33) * 18;
        final scale = 1 + 0.05 * math.sin(2 * math.pi * s / 19);

        return Transform(
          key: const ValueKey('brand-backdrop-glow'),
          alignment: Alignment.center,
          transform: Matrix4.translationValues(dx, dy, 0)..scale(scale),
          child: glow,
        );
      },
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary100.withOpacity(0.55),
                AppColors.primary100.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A lattice of eight-point stars (two squares rotated 45° — the رُبع الحزب
/// motif). The fade-out is applied by [_DriftingLattice], not here, so the
/// painted pattern can move while the fade stays anchored.
class _ArabesquePainter extends CustomPainter {
  const _ArabesquePainter();

  /// Well under the 6–8% ceiling: the motif should register as texture, never
  /// as content competing with the text above it.
  static const double _opacity = 0.05;
  static const double tile = 64;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.brandPrimary.withOpacity(_opacity);

    for (double y = tile / 2; y < size.height + tile; y += tile) {
      for (double x = tile / 2; x < size.width + tile; x += tile) {
        _star(canvas, Offset(x, y), tile * 0.34, paint);
      }
    }
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
