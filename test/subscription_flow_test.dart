import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/contact/views/faq_view.dart';

/// The subscriptions flow: free plan -> alert -> plans for the student's grade
/// -> payment page (amount + transfer accounts from the dashboard) -> receipt.
Student _student({
  bool expired = false,
  bool paid = false,
  bool pending = false,
}) =>
    Student.fromJson({
      'id': 1,
      'phone1': '01000000000',
      'academic_year': '1',
      'is_active': true,
      'is_profile_completed': true,
      'is_upload_paid_certificate': paid,
      'has_paid_subscription': paid,
      'payment_pending': pending,
      'free_plan_expired': expired,
    });

void main() {
  group('payment accounts come from the dashboard', () {
    test('parsed per package', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 1,
        'name': 'باقة الصف الأول والثاني',
        'price': 200,
        'period_type': 'year',
        'period_value': 1,
        'payment_accounts': [
          {'label': 'فودافون كاش', 'value': '01000000000'},
          {'label': 'إنستا باي', 'value': 'rawasi@instapay'},
          {'label': 'فارغ', 'value': ''},
        ],
      });

      expect(plan.paymentAccounts.map((a) => a.value),
          ['01000000000', 'rawasi@instapay'],
          reason: 'an account with no number is useless and is dropped');
      expect(plan.paymentAccounts.first.label, 'فودافون كاش');
    });

    test('an older backend sends none, so the page falls back to the old number', () {
      final plan = SubscriptionPlan.fromJson({
        'id': 1, 'name': 'باقة', 'price': 200, 'period_type': 'year', 'period_value': 1,
      });

      expect(plan.paymentAccounts, isEmpty);
      expect(PaymentAccount.legacy.single.value, '01027252071');
    });
  });

  group('the free-plan alert says why', () {
    test('25% of the subject', () {
      final copy = SubscriptionView.paywallCopy(trialEnded: false, paymentPending: false);

      expect(copy.body, contains('25%'));
      expect(copy.body, contains('اشترك لمتابعة باقي الدروس'));
    });

    test('the 15 days ended', () {
      final copy = SubscriptionView.paywallCopy(trialEnded: true, paymentPending: false);

      expect(copy.title, 'انتهت الفترة المجانية');
      expect(copy.body, contains('15'));
    });

    test('a receipt is already under review — do not ask them to pay again', () {
      final copy = SubscriptionView.paywallCopy(trialEnded: true, paymentPending: true);

      expect(copy.title, contains('قيد المراجعة'));
      expect(copy.body, isNot(contains('اشترك')));
    });
  });

  group('the mandatory redirect after 15 days', () {
    test('forces a free student whose period ended', () {
      expect(SubscriptionView.shouldForceRedirect(_student(expired: true)), isTrue);
    });

    test('leaves a student still inside the 15 days alone', () {
      expect(SubscriptionView.shouldForceRedirect(_student()), isFalse);
    });

    test('never touches a paid student', () {
      expect(SubscriptionView.shouldForceRedirect(_student(expired: true, paid: true)), isFalse);
    });

    test('does not nag a student whose receipt is under review', () {
      expect(SubscriptionView.shouldForceRedirect(_student(expired: true, pending: true)), isFalse);
    });

    test('does nothing without a profile', () {
      expect(SubscriptionView.shouldForceRedirect(null), isFalse);
    });
  });

  group('FAQ', () {
    test('is exactly the new 21 questions', () {
      expect(faqItems, hasLength(21));
      expect(faqItems.first['question'], startsWith('ما هي الاستراتيجية الذهبية'));
      expect(faqItems.last['question'], startsWith('إيه اللي يميز رواسي'));
      for (final item in faqItems) {
        expect(item['question'], isNotEmpty);
        expect(item['answer'], isNotEmpty);
      }
    });

    test('none of the old, outdated answers remain', () {
      final all = faqItems.map((i) => '${i['question']} ${i['answer']}').join(' ');

      expect(all, isNot(contains('90 يوم')), reason: 'the retired 90-day plan');
      expect(all, isNot(contains('أوفلاين')), reason: 'retired offline videos');
      expect(all, contains('أول 15 يوماً مجاناً'));
    });
  });
}
