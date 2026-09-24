// lib/shared/account_gate.dart
//
// The single screen shown to a student who is registered but cannot reach
// content yet.
//
// free first month: there is no payment step, so the only thing standing
// between a registered student and the app is an admin setting is_active. That
// makes one message correct everywhere - courses, library, home - where three
// different ones used to contradict each other ("استكمل بياناتك" on courses,
// "أكمل اشتراكك" in the library, "حسابك قيد المراجعة" elsewhere).
//
// CheckStudentActive returns the same wording, so a raw API error and this
// screen cannot disagree either.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

/// Why a student cannot get in yet.
enum GateReason {
  /// Not signed in at all.
  signedOut,

  /// Signed in, profile still unfinished. Reachable only if the student left
  /// the flow before submitting - the form itself guarantees completion.
  profileIncomplete,

  /// Registered and complete, waiting on an admin to activate the account.
  underReview,
}

/// Works out which gate applies, or null when the student is free to proceed.
GateReason? gateFor(Student? profile) {
  if (profile == null) return GateReason.signedOut;
  if (!profile.isProfileCompleted) return GateReason.profileIncomplete;
  if (!profile.isActive) return GateReason.underReview;

  // free first month: isUploadPaidCertificate is deliberately NOT consulted.
  // The receipt step is gone from the app and its middleware check is
  // commented out server-side, so gating on it would lock out every student.
  return null;
}

/// The shared gate screen. [action] is the optional call to action - e.g. the
/// login/register pair, or a button that opens the rest of the profile form.
class AccountGate extends StatelessWidget {
  final GateReason reason;
  final Widget? action;

  const AccountGate({super.key, required this.reason, this.action});

  static const String underReviewTitle = 'حسابك قيد المراجعة';
  static const String underReviewBody =
      'تم استلام بياناتك بنجاح، وسيتم تفعيل حسابك من الإدارة في أقرب وقت.';

  IconData get _icon => switch (reason) {
        GateReason.signedOut => Icons.lock_outline,
        GateReason.profileIncomplete => Icons.person_outline,
        GateReason.underReview => Icons.hourglass_top_outlined,
      };

  String get _title => switch (reason) {
        GateReason.signedOut => 'لابد من تسجيل الدخول أولًا',
        GateReason.profileIncomplete => 'استكمل بياناتك',
        GateReason.underReview => underReviewTitle,
      };

  String get _body => switch (reason) {
        GateReason.signedOut =>
          'سجّل الدخول أو أنشئ حسابًا جديدًا للوصول إلى المحتوى.',
        GateReason.profileIncomplete =>
          'يرجى استكمال بيانات ملفك الشخصي للمتابعة.',
        GateReason.underReview => underReviewBody,
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary100),
              ),
              child: Icon(_icon, size: 48, color: AppColors.brandPrimary),
            ),
            const Gap(20),
            CustomText(
              text: _title,
              color: AppColors.gray900,
              size: 20,
              weight: FontWeight.bold,
              align: TextAlign.center,
            ),
            const Gap(10),
            CustomText(
              text: _body,
              color: AppColors.gray700,
              size: 14,
              align: TextAlign.center,
            ),
            if (action != null) ...[
              const Gap(24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
