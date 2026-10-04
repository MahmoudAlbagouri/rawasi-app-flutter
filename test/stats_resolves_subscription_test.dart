import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/home/widgets/trial_card.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/features/stats/widgets/mastery_card.dart';
import 'package:rawasi_app_n/features/stats/widgets/my_rank_card.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';

/// Points = new + re-solved questions; the mastery rate; weekly rank movement;
/// and the paid package replacing the free-trial card.
void main() {
  group('points breakdown', () {
    test('new and re-solved questions are read separately', () {
      final board = Leaderboard.fromJson({
        'top': [],
        'me': {'rank': 4, 'points': 520, 'new_questions': 420, 'resolved_questions': 100, 'rank_change_week': 72},
        'scope': {'academic_year': '1'},
      });

      expect(board.myPoints, 520);
      expect(board.myNewQuestions, 420);
      expect(board.myResolvedQuestions, 100);
      expect(board.rankChangeWeek, 72);
    });

    test('an older backend: every point was a first solve, no weekly change', () {
      final board = Leaderboard.fromJson({
        'top': [],
        'me': {'rank': 4, 'points': 58},
        'scope': {'academic_year': '1'},
      });

      expect(board.myNewQuestions, 58);
      expect(board.myResolvedQuestions, 0);
      expect(board.rankChangeWeek, isNull);
    });

    test('Arabic counts read naturally', () {
      expect(arabicQuestions(420), '420 سؤالًا');
      expect(arabicQuestions(5), '5 أسئلة');
      expect(arabicPlaces(72), '72 مركزًا');
      expect(arabicPlaces(2), 'مركزين');
    });
  });

  group('weekly rank movement', () {
    test('up, down, unchanged, and nothing to compare', () {
      expect(MyRankCard.weeklyLabel(72), 'تقدمت 72 مركزًا هذا الأسبوع');
      expect(MyRankCard.weeklyLabel(-3), 'تراجعت 3 مراكز هذا الأسبوع');
      expect(MyRankCard.weeklyLabel(0), 'حافظت على مركزك هذا الأسبوع');
      expect(MyRankCard.weeklyLabel(null), isNull);
    });
  });

  group('mastery', () {
    test('parses the server figure and its model', () {
      final m = Mastery.fromJson({'percentage': 84, 'target_repetitions': 5, 'open_lessons': 12, 'mastered_lessons': 7});

      expect(m.percentage, 84);
      expect(MasteryCard.percentLabel(m.percentage), '84%');
      expect(MasteryCard.percentLabel(62.5), '62.5%');
      expect(MasteryCard.explanation(m.targetRepetitions), contains('5 مرات'));
      expect(MasteryCard.explanation(5), contains('100%'));
    });

    test('an older backend sends none: zero, never a crash', () {
      final stats = StudentStats.fromJson({});

      expect(stats.mastery.percentage, 0);
      expect(stats.mastery.targetRepetitions, 5);
    });
  });

  group('the plan card', () {
    final trial = Trial.fromJson({'started': true, 'total_days': 15, 'days_used': 13, 'days_remaining': 2});

    test('a paid student gets the package, with its expiry', () {
      final sub = Subscription.fromJson({
        'is_paid': true, 'plan_name': 'باقة الصف الأول والثاني',
        'started_at': '2026-10-01', 'expires_at': '2027-10-01',
      });

      expect(sub.isPaid, isTrue);
      expect(sub.expiresAt, '2027-10-01');
      expect(TrialCard.hasContent(trial, sub), isTrue);
    });

    test('a free student keeps the trial countdown', () {
      expect(TrialCard.hasContent(trial, const Subscription()), isTrue);
    });

    test('nothing to show for a student who is neither in trial nor paid', () {
      final notStarted = Trial.fromJson({'started': false, 'total_days': 15});

      expect(TrialCard.hasContent(notStarted, const Subscription()), isFalse);
    });
  });
}
