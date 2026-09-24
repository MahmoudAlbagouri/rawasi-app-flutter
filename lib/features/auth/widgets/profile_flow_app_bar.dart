// lib/features/auth/widgets/profile_flow_app_bar.dart
//
// Shared chrome for the registration / complete-profile steps (2-5).
//
// Why this exists: every step used a bare `Navigator.pop(context)`. Some steps
// are entered with `pushAndRemoveUntil` (login → step 4 when the profile is
// incomplete) or `pushReplacement` (step 3 → step 4), so there is no route
// underneath — popping emptied the navigator and left a black screen. Back here
// only pops when something is there to pop to, and otherwise lands on a real
// root. The same guard covers the Android system back gesture.

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

/// Leaves the flow for a real root: home for a signed-in student (the usual
/// case here — steps 4 and 5 run after check-otp issued a token), login
/// otherwise. `pushAndRemoveUntil` so back cannot return into a half-filled
/// form.
Future<void> leaveProfileFlow(BuildContext context) async {
  final signedIn = await isUserSignedIn();
  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => signedIn ? const HomeView() : const LoginView(),
    ),
    (route) => false,
  );
}

/// Back for the profile flow: pop if possible, otherwise leave for a root.
Future<void> backOutOfProfileFlow(BuildContext context) async {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
    return;
  }
  await leaveProfileFlow(context);
}

class ProfileFlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// While a request is in flight both actions are disabled, so a back or skip
  /// cannot race the submit and navigate away mid-request.
  final bool isBusy;

  /// Steps that can be skipped show "تخطي"; set false to hide it.
  final bool showSkip;

  const ProfileFlowAppBar({
    super.key,
    required this.title,
    this.isBusy = false,
    this.showSkip = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
        onPressed: isBusy ? null : () => backOutOfProfileFlow(context),
      ),
      title: CustomText(
        text: title,
        color: AppColors.brandPrimary,
        size: 18,
        weight: FontWeight.w600,
      ),
      centerTitle: true,
      actions: [
        if (showSkip)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton(
              onPressed: isBusy ? null : () => leaveProfileFlow(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gray600,
                disabledForegroundColor: AppColors.gray300,
              ),
              // Nothing typed so far is sent anywhere: skipping makes no API
              // call, so the profile simply stays incomplete and home keeps
              // prompting the student to finish it.
              child: const Text(
                'تخطي',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

/// Wraps a profile-flow screen so the Android back gesture takes the same
/// guarded path as the app bar's arrow instead of emptying the navigator.
class ProfileFlowPopScope extends StatelessWidget {
  final Widget child;
  final bool isBusy;

  const ProfileFlowPopScope({
    super.key,
    required this.child,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Let Flutter pop normally only when there is a route below and no
      // request is running; otherwise handle it ourselves.
      canPop: !isBusy && Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || isBusy) return;
        leaveProfileFlow(context);
      },
      child: child,
    );
  }
}
