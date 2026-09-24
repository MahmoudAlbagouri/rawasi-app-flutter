// lib/shared/auth_actions.dart
//
// The login / create-account pair, in one place.
//
// Every pre-auth surface offers both routes in and keeps the same hierarchy:
// one filled primary button for the action that screen is about, one outlined
// secondary for the other. Built as a single widget so the pair cannot drift
// in wording, order or emphasis from screen to screen.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/views/login_view.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_1.dart';

/// Which of the two actions this screen treats as its primary one.
enum AuthAction { login, register }

class AuthActions extends StatelessWidget {
  /// The filled button. The other action is rendered outlined.
  final AuthAction primary;

  /// Replaces the default push for the primary action - used by the login
  /// screen, where the primary button submits the form rather than navigating.
  final VoidCallback? onPrimary;

  /// Disables both buttons (e.g. while the login request is in flight).
  final bool isBusy;

  /// Set when the screen is already the login/register screen itself, so the
  /// primary action does not push a second copy of it onto the stack.
  final bool replaceOnNavigate;

  const AuthActions({
    super.key,
    this.primary = AuthAction.login,
    this.onPrimary,
    this.isBusy = false,
    this.replaceOnNavigate = false,
  });

  static const String loginLabel = 'تسجيل الدخول';
  static const String registerLabel = 'إنشاء حساب جديد';

  void _go(BuildContext context, AuthAction action) {
    final route = MaterialPageRoute<void>(
      builder: (_) => action == AuthAction.login
          ? const LoginView()
          : const RegisterStep1View(),
    );

    // From login → register (or back) we swap rather than stack, so the two
    // screens cannot pile up on each other as the student changes their mind.
    replaceOnNavigate
        ? Navigator.pushReplacement(context, route)
        : Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final secondary =
        primary == AuthAction.login ? AuthAction.register : AuthAction.login;

    String label(AuthAction a) =>
        a == AuthAction.login ? loginLabel : registerLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isBusy
                ? null
                : (onPrimary ?? () => _go(context, primary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              disabledBackgroundColor: AppColors.gray300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label(primary),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isBusy ? null : () => _go(context, secondary),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.brandPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              label(secondary),
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
