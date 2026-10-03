import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/courses/data/lesson.dart';
import 'package:rawasi_app_n/features/courses/views/course_lessons_view.dart';

/// A student on the free plan reaches the first 25% of each subject. Beyond
/// that, lessons arrive locked with `requires_payment`, and the app has to tell
/// that lock apart from the ordinary sequential one — the two need different
/// sentences, because only one of them is something the student can act on
/// today.
Map<String, dynamic> _json({
  String status = 'locked',
  bool unlocked = false,
  bool completed = false,
  bool? requiresPayment,
  int? freeLimit,
  String? paywallReason,
}) => {
  'id': 7,
  'course_id': 3,
  'title': 'الدرس السابع',
  'order': 7,
  'status': status,
  'is_unlocked': unlocked,
  'is_completed': completed,
  'questions_count': 4,
  'completed_questions_count': 0,
  'unlocked_at': null,
  if (requiresPayment != null) 'requires_payment': requiresPayment,
  if (freeLimit != null) 'free_limit_lessons': freeLimit,
  if (paywallReason != null) 'paywall_reason': paywallReason,
};

void main() {
  group('parsing', () {
    test('a paywalled lesson carries the flag and the allowance', () {
      final lesson = Lesson.fromJson(
        _json(requiresPayment: true, freeLimit: 2),
      );

      expect(lesson.requiresPayment, isTrue);
      expect(lesson.freeLimitLessons, 2);
      expect(lesson.isUnlocked, isFalse);
      expect(lesson.status, 'locked');
    });

    test('an ordinary sequential lock is not a paywall', () {
      final lesson = Lesson.fromJson(
        _json(requiresPayment: false, freeLimit: 2),
      );

      expect(lesson.requiresPayment, isFalse);
      expect(
        lesson.freeLimitLessons,
        2,
        reason: 'the allowance is still reported, so the notice can be shown',
      );
    });

    test('a paid student has no allowance', () {
      final lesson = Lesson.fromJson(_json(status: 'unlocked', unlocked: true));

      expect(lesson.freeLimitLessons, isNull);
      expect(lesson.requiresPayment, isFalse);
    });

    test('an older payload without either key parses as uncapped', () {
      // The app must keep working against a backend that has not shipped this
      // yet, and must not invent a paywall where the server reported none.
      final lesson = Lesson.fromJson(_json(status: 'unlocked', unlocked: true));

      expect(lesson.requiresPayment, isFalse);
      expect(lesson.freeLimitLessons, isNull);
    });
  });

  group('the allowance notice', () {
    // The view's own rule. `total` is the CURRICULUM total — the "X من 23"
    // the progress bars show — not the lessons uploaded so far.
    final show = CourseLessonsView.showAllowanceNotice;

    test('appears when the course has more lessons than the allowance', () {
      expect(show(5, 23), isTrue);
    });

    test('stays hidden for a paid student', () {
      expect(show(null, 23), isFalse);
    });

    test('stays hidden when the allowance already covers everything', () {
      // Nothing is withheld, so saying "2 of 2 free" would be noise.
      expect(show(2, 2), isFalse);
    });

    test('counts the curriculum, not what is uploaded', () {
      // 4 of 39 lessons uploaded, allowance 9: the subject is still capped.
      expect(show(9, 39), isTrue);
    });
  });

  group('why a lesson is paywalled', () {
    test('the 25% cap', () {
      final l = Lesson.fromJson(
        _json(
          requiresPayment: true,
          freeLimit: 5,
          paywallReason: Lesson.paywallFreeLimit,
        ),
      );

      expect(l.requiresPayment, isTrue);
      expect(l.isTrialEndedPaywall, isFalse);
    });

    test('the 15-day free period', () {
      final l = Lesson.fromJson(
        _json(requiresPayment: true, paywallReason: Lesson.paywallTrialEnded),
      );

      expect(l.isTrialEndedPaywall, isTrue);
    });

    test('an older backend sends no reason', () {
      final l = Lesson.fromJson(_json(requiresPayment: true, freeLimit: 2));

      expect(l.paywallReason, isNull);
      expect(l.isTrialEndedPaywall, isFalse);
    });
  });

  group('payment state on the profile', () {
    Map<String, dynamic> profile(Map<String, dynamic> extra) => {
      'id': 1,
      'phone1': '01000000000',
      'academic_year': '1',
      'is_active': true,
      'is_profile_completed': true,
      ...extra,
    };

    test('a pending receipt is not a paid subscription', () {
      final s = Student.fromJson(
        profile({
          'is_upload_paid_certificate': false,
          'has_paid_subscription': false,
          'payment_pending': true,
        }),
      );

      expect(s.paymentPending, isTrue);
      expect(s.hasPaidSubscription, isFalse);
    });

    test('an approved payment is', () {
      final s = Student.fromJson(
        profile({
          'is_upload_paid_certificate': true,
          'has_paid_subscription': true,
          'payment_pending': false,
        }),
      );

      expect(s.hasPaidSubscription, isTrue);
      expect(s.paymentPending, isFalse);
    });

    test('an older backend falls back to the flag itself', () {
      final s = Student.fromJson(profile({'is_upload_paid_certificate': true}));

      expect(s.hasPaidSubscription, isTrue);
      expect(s.paymentPending, isFalse);
      expect(s.freePlanExpired, isFalse);
    });
  });

  group('the plans a student can buy', () {
    SubscriptionPlan plan(int id, double price) => SubscriptionPlan.fromJson({
      'id': id,
      'name': 'باقة $id',
      'price': price,
      'period_type': 'year',
      'period_value': 1,
    });

    test('never include the free plan everyone already has', () {
      final plans = SubscriptionView.purchasable([
        plan(4, 0),
        plan(1, 200),
        plan(2, 60),
      ]);

      expect(plans.map((p) => p.id), [1, 2]);
    });
  });
}
