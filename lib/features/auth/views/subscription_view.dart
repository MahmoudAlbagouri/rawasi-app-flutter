// lib/features/auth/views/subscription_view.dart
//
// The "الاشتراك" entry in حسابي.
//
// free first month: there is nothing to buy and nothing to upload, so this
// screen reports the student's standing instead of selling a plan. The paid
// path is not deleted — SubscriptionRepo, SubscriptionCard and
// UploadCertificateView are all still in the codebase, and the
// upload-paid-certificate route and column still exist server-side — it is
// simply no longer reachable from the app.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late Future<Student?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Student?> _loadProfile() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) return null;
    try {
      return await ProfileRepository().fetchProfile();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'الاشتراك',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Student?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const AccountGate(
                reason: GateReason.signedOut,
                action: AuthActions(),
              );
            }

            final reason = gateFor(profile);
            if (reason != null) return AccountGate(reason: reason);

            return _freeMonthCard();
          },
        ),
      ),
    );
  }

  Widget _freeMonthCard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.success50,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success500),
              ),
              child: const Icon(
                Icons.card_giftcard_outlined,
                size: 48,
                color: AppColors.success600,
              ),
            ),
            const Gap(20),
            const CustomText(
              text: 'اشتراكك مفعّل — الشهر الأول مجانًا',
              color: AppColors.gray900,
              size: 20,
              weight: FontWeight.bold,
              align: TextAlign.center,
            ),
            const Gap(10),
            const CustomText(
              text:
                  'يمكنك الوصول إلى جميع المواد والدروس دون أي رسوم. سنخبرك قبل انتهاء الفترة المجانية.',
              color: AppColors.gray700,
              size: 14,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
