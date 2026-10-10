// lib/features/home/widgets/guest_trial_banner.dart
//
// The pre-registration promo: what a brand-new, signed-out student sees first.
//
// It says three things, in this order — there IS a free trial, it is open to
// all three secondary grades, and here is how to start — and sits at the very
// top of home, above even the stats placeholder, because home is the app's
// landing screen (the splash goes straight to it).
//
// It reuses AuthActions for the buttons, so the register / login pair keeps
// the wording and hierarchy every other pre-auth screen has.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

/// Length of the free period, for a student who has no account yet.
///
/// A signed-out visitor has no profile to read it from (the trial summary is
/// an authenticated endpoint), so this mirrors the server's
/// `subscription.free_trial_days`. Once an account exists the app shows the
/// server's own figure (TrialCard) and never this one.
const int kGuestTrialDays = 15;

/// The grades the offer is open to, as the banner names them.
const List<String> kGuestTrialGrades = [
  'الأول الثانوي',
  'الثاني الثانوي',
  'الثالث الثانوي',
];

class GuestTrialBanner extends StatelessWidget {
  const GuestTrialBanner({super.key});

  /// "سجّل الآن واحصل على 15 يومًا تجربة مجانية بالكامل".
  static String get headline =>
      'سجّل الآن واحصل على ${arabicDays(kGuestTrialDays)} تجربة مجانية بالكامل';

  static const String subtitle =
      'العرض متاح لطلاب الصفوف الثلاثة، وتبدأ بدون اختيار باقة أو دفع أي رسوم.';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary100),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: const AuthActions(primary: AuthAction.register),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.primary700, AppColors.brandPrimary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandWarning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomText(
                  text: '${arabicDays(kGuestTrialDays)} مجانًا',
                  color: AppColors.brandGray,
                  size: 12,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(14),
          CustomText(
            text: headline,
            color: Colors.white,
            size: 19,
            weight: FontWeight.bold,
          ),
          const Gap(6),
          const CustomText(
            text: subtitle,
            color: Colors.white,
            size: 13,
          ),
          const Gap(14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final grade in kGuestTrialGrades) _GradeChip(label: grade),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String label;

  const _GradeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 15),
          const Gap(6),
          CustomText(
            text: label,
            color: Colors.white,
            size: 12.5,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
