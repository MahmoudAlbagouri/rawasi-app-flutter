// lib/features/auth/views/subscription_view.dart
//
// "الاشتراك": where the free-plan paywall ("اشترك لمتابعة باقي الدروس") leads,
// and the entry in حسابي.
//
// The free plan is two limits, whichever comes first: 15 days from activation
// and 25% of each course. Paying lifts both. There is no payment gateway — the
// student transfers the fee, picks a paid plan here and uploads the receipt
// (UploadCertificateView). That only creates a PENDING request: an admin
// approves it in the dashboard, and only then does the server stop applying
// the free-plan limits. Nothing about the student's progress changes — they
// carry on in the same course from exactly where they stopped.
//
// Three states, all read from the server (never inferred on the device):
//   paid     — has_paid_subscription: nothing to sell.
//   pending  — payment_pending: receipt is with an admin; say so, sell nothing.
//   free     — list the paid plans for the student's grade.
//
// Opened with SubscriptionView.open(context); it completes with true when the
// student uploaded a receipt, so the caller can refresh what it shows.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_repo.dart';
import 'package:rawasi_app_n/features/auth/views/upload_certificate_view.dart';
import 'package:rawasi_app_n/features/auth/widgets/card_subscription.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  /// Opens the screen; true when a receipt was uploaded.
  static Future<bool> open(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionView()),
    );
    return result == true;
  }

  /// Why the free plan stopped this student, in one sentence each. Kept here
  /// so the lesson list, the lesson flow and home all say the same thing.
  @visibleForTesting
  static ({String title, String body}) paywallCopy({
    required bool trialEnded,
    required bool paymentPending,
  }) {
    if (paymentPending) {
      return (
        title: 'طلب اشتراكك قيد المراجعة',
        body: 'استلمنا إيصال الدفع، وسيُفتح باقي الدروس فور تأكيده.',
      );
    }
    if (trialEnded) {
      return (
        title: 'انتهت الفترة المجانية',
        body: 'انتهت مدة الخطة المجانية (15 يومًا). اشترك لمتابعة باقي الدروس.',
      );
    }
    return (
      title: 'انتهى الحد المجاني لهذه المادة',
      body:
          'لا يمكن أن يتجاوز المحتوى في الخطة المجانية 25% من دروس هذه المادة. اشترك لمتابعة باقي الدروس.',
    );
  }

  /// The free-plan stop: an alert saying WHY, then straight to the plans.
  ///
  /// Not dismissible by tapping outside — the student acknowledges it and is
  /// taken to the subscriptions page, as the paywall requires. They can still
  /// come back from there to finished lessons, which stay open.
  /// Completes with true when a receipt was uploaded.
  static Future<bool> showPaywall(
    BuildContext context, {
    required bool trialEnded,
    bool paymentPending = false,
  }) async {
    final copy = paywallCopy(
      trialEnded: trialEnded,
      paymentPending: paymentPending,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          paymentPending ? Icons.hourglass_top : Icons.workspace_premium,
          color: AppColors.warning700,
          size: 36,
        ),
        title: Text(copy.title, textAlign: TextAlign.center),
        content: Text(copy.body, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
            ),
            child: Text(paymentPending ? 'متابعة الطلب' : 'عرض الباقات'),
          ),
        ],
      ),
    );

    if (!context.mounted) return false;
    return open(context);
  }

  /// Whether the free period has ended for a student who has neither paid nor
  /// sent a receipt yet — the only case the app forces to the plans page.
  @visibleForTesting
  static bool shouldForceRedirect(Student? profile) =>
      profile != null &&
      profile.freePlanExpired &&
      !profile.hasPaidSubscription &&
      !profile.paymentPending;

  /// The 15-day redirect from home fires once per app session, not on every
  /// rebuild or tab switch — courses still redirect each time one is opened.
  static bool _expiryRedirectShown = false;

  /// Forces the subscriptions page when the free period has ended. Home calls
  /// this once data is loaded; it is a no-op for paid or pending students.
  static Future<void> redirectIfFreePlanExpired(
    BuildContext context,
    Student? profile, {
    bool oncePerSession = false,
  }) async {
    if (!shouldForceRedirect(profile)) return;
    if (oncePerSession) {
      if (_expiryRedirectShown) return;
      _expiryRedirectShown = true;
    }
    await showPaywall(context, trialEnded: true);
  }

  /// Only plans that cost something can be bought; the seeded free plan is
  /// what every student already has.
  @visibleForTesting
  static List<SubscriptionPlan> purchasable(List<SubscriptionPlan> plans) =>
      plans.where((p) => p.price > 0).toList();

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _Page {
  final Student? profile;
  final List<SubscriptionPlan> plans;
  final String? plansError;

  const _Page({this.profile, this.plans = const [], this.plansError});
}

class _SubscriptionViewState extends State<SubscriptionView> {
  late Future<_Page> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Page> _load() async {
    if (!await isUserSignedIn()) return const _Page();

    final Student profile;
    try {
      profile = await ProfileRepository().fetchProfile();
    } catch (_) {
      return const _Page();
    }

    // Plans are only needed by a student who can still buy one.
    if (profile.hasPaidSubscription || profile.paymentPending) {
      return _Page(profile: profile);
    }

    try {
      final plans = await SubscriptionRepo().fetchPlans(
        grade: profile.academicYear,
      );
      return _Page(
        profile: profile,
        plans: SubscriptionView.purchasable(plans),
      );
    } catch (e) {
      return _Page(
        profile: profile,
        plansError: e is ApiError
            ? e.message
            : 'تعذّر تحميل الباقات، حاول مرة أخرى',
      );
    }
  }

  Future<void> _choose(SubscriptionPlan plan) async {
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UploadCertificateView(
          planId: plan.id,
          planName: plan.name,
          planPrice: plan.price,
          hasDiscount: plan.hasDiscount,
          paymentAccounts: plan.paymentAccounts,
        ),
      ),
    );
    if (!mounted) return;
    if (uploaded == true) {
      // Straight back to wherever the paywall was, which now shows the
      // request as pending.
      Navigator.pop(context, true);
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
          onPressed: () => Navigator.pop(context, false),
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
        child: FutureBuilder<_Page>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final page = snapshot.data ?? const _Page();
            final profile = page.profile;
            if (profile == null) {
              return const AccountGate(
                reason: GateReason.signedOut,
                action: AuthActions(),
              );
            }

            final reason = gateFor(profile);
            if (reason != null) return AccountGate(reason: reason);

            if (profile.hasPaidSubscription) return _paid();
            if (profile.paymentPending) return _pending();
            return _plans(page, profile);
          },
        ),
      ),
    );
  }

  Widget _status({
    required IconData icon,
    required Color color,
    required Color tint,
    required String title,
    required String body,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: tint,
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const Gap(20),
            CustomText(
              text: title,
              color: AppColors.gray900,
              size: 20,
              weight: FontWeight.bold,
              align: TextAlign.center,
            ),
            const Gap(10),
            CustomText(
              text: body,
              color: AppColors.gray700,
              size: 14,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paid() => _status(
    icon: Icons.workspace_premium,
    color: AppColors.success600,
    tint: AppColors.success50,
    title: 'اشتراكك مفعّل',
    body: 'يمكنك متابعة جميع الدروس في كل المواد من حيث توقفت.',
  );

  Widget _pending() => _status(
    icon: Icons.hourglass_top,
    color: AppColors.warning700,
    tint: AppColors.warning50,
    title: 'طلب اشتراكك قيد المراجعة',
    body:
        'استلمنا إيصال الدفع وسيتم تفعيل اشتراكك بعد التأكد منه. ستصلك رسالة عند التفعيل، وتكمل بعدها دروسك من حيث توقفت.',
  );

  Widget _plans(_Page page, Student profile) {
    final header = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard_outlined,
            color: AppColors.brandPrimary,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: profile.freePlanExpired
                      ? 'انتهت الفترة المجانية'
                      : 'أنت على الخطة المجانية',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                const Gap(4),
                const CustomText(
                  text:
                      'الخطة المجانية: أول 15 يومًا وربع دروس كل مادة. اشترك لمتابعة باقي الدروس دون أن تفقد أي تقدم.',
                  color: AppColors.gray700,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        header,
        const Gap(20),
        const CustomText(
          text: 'اختر باقتك',
          color: AppColors.gray900,
          size: 17,
          weight: FontWeight.bold,
        ),
        const Gap(12),
        if (page.plansError != null)
          Column(
            children: [
              CustomText(
                text: page.plansError!,
                color: AppColors.error600,
                size: 14,
                align: TextAlign.center,
              ),
              const Gap(8),
              TextButton(
                onPressed: () => setState(() => _future = _load()),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          )
        else if (page.plans.isEmpty)
          const CustomText(
            text:
                'لا توجد باقات متاحة لصفك الدراسي حاليًا. تواصل معنا للاشتراك.',
            color: AppColors.gray600,
            size: 14,
            align: TextAlign.center,
          )
        else
          for (final plan in page.plans) ...[
            SubscriptionCard(plan: plan, onPressed: () => _choose(plan)),
            const Gap(12),
          ],
      ],
    );
  }
}
