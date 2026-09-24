// lib/shared/home_section.dart
//
// The building blocks the home sections share: a card shell, a section
// heading, a skeleton bar and a progress bar that counts up on first paint.
//
// Accessibility: every animation here checks MediaQuery.disableAnimations and
// renders the final state immediately when the viewer has asked the system to
// reduce motion. Nothing loops or pulses once it has settled — this screen is
// meant to be sat in front of for long stretches, so nothing moves in the
// periphery while the student is reading.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

/// True when the viewer has asked the platform to reduce motion.
bool motionReduced(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// The white rounded card every home section sits in.
class HomeCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const HomeCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.gray200),
      boxShadow: [
        BoxShadow(
          color: AppColors.gray200.withOpacity(0.35),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A right-aligned section heading, optionally with a trailing action.
class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            text: title,
            color: AppColors.brandPrimary,
            size: 17,
            weight: FontWeight.bold,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: actionLabel!,
                  color: AppColors.brandPrimary,
                  size: 13,
                  weight: FontWeight.w600,
                ),
                const Gap(2),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 11,
                  color: AppColors.brandPrimary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A grey bar standing in for content that has not arrived yet.
///
/// Reserves real height so the layout does not jump when the data lands. It
/// does not shimmer: a looping animation in the corner of the eye is exactly
/// what this screen should not have.
class SkeletonBar extends StatelessWidget {
  final double? width;
  final double height;
  final bool animate;

  const SkeletonBar({
    super.key,
    this.width,
    this.height = 12,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200.withOpacity(animate ? 0.7 : 0.4),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// A progress bar that counts up from zero the first time it is painted, then
/// stays put. Later value changes animate from wherever it currently is.
class AnimatedProgressBar extends StatelessWidget {
  /// 0.0–1.0.
  final double value;
  final double height;
  final Color? color;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final bar = (double v) => ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: v,
            minHeight: height,
            backgroundColor: AppColors.gray200,
            color: color ??
                (target >= 1 ? AppColors.success600 : AppColors.brandPrimary),
          ),
        );

    if (motionReduced(context)) return bar(target);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => bar(v),
    );
  }
}
