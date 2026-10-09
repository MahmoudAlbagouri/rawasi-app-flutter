import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/question.dart';
import 'package:rawasi_app_n/features/courses/data/replay_progress.dart';

/// resolveReplayOutcome is the one place that decides what a saved replay
/// sitting resumes into. Every question here is already `is_completed =
/// true` — that is what makes it a replay — so `isCompleted` is irrelevant
/// to these tests and left true throughout; only the saved ids decide what
/// happens.
Question _q(int id) => Question(
  questionId: id,
  lessonId: 7,
  type: 'definitions',
  question: 'سؤال $id',
  answer: 'إجابة $id',
  isCompleted: true,
);

void main() {
  final lesson = List.generate(6, (i) => _q(i + 1)); // ids 1..6

  group('nothing saved', () {
    test('returns null — an ordinary fresh replay', () {
      expect(resolveReplayOutcome(lesson, ReplayProgress.empty), isNull);
    });
  });

  group('the first pass still has work left', () {
    test('resumes with exactly what remains, in lesson order', () {
      final outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(firstPassJudgedIds: [1, 2, 3]),
      );

      expect(outcome, isNotNull);
      expect(outcome!.kind, ReplayOutcomeKind.firstPass);
      expect(outcome.nextIds, [4, 5, 6]);
      expect(outcome.alreadyDone, 3);
      expect(outcome.easyCount, 3);
      expect(outcome.reviewQueueIds, isEmpty);
    });

    test('deferred ("جيد") ids are restored as the review queue', () {
      final outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(
          firstPassJudgedIds: [1, 2, 3],
          reviewQueueIds: [2],
        ),
      );

      expect(outcome!.reviewQueueIds, [2]);
      // Judged 3, one of them deferred rather than marked easy.
      expect(outcome.easyCount, 2);
      expect(outcome.nextIds, [4, 5, 6]);
    });

    test('one question judged is still a resumable first pass', () {
      final outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(firstPassJudgedIds: [1]),
      );

      expect(outcome!.kind, ReplayOutcomeKind.firstPass);
      expect(outcome.nextIds, [2, 3, 4, 5, 6]);
      expect(outcome.alreadyDone, 1);
    });

    test('all but one judged leaves exactly that one', () {
      final outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(firstPassJudgedIds: [1, 2, 3, 4, 5]),
      );

      expect(outcome!.nextIds, [6]);
      expect(outcome.alreadyDone, 5);
    });
  });

  group('the first pass finished before the student left', () {
    test('with something deferred, resumes into the review tail', () {
      final outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(
          firstPassJudgedIds: [1, 2, 3, 4, 5, 6],
          reviewQueueIds: [2, 5],
        ),
      );

      expect(outcome!.kind, ReplayOutcomeKind.reviewTail);
      expect(outcome.nextIds, [2, 5]);
      // The resume notice is scoped to the first pass only - there is none
      // to show for a review-tail restart.
      expect(outcome.alreadyDone, 0);
      expect(outcome.reviewQueueIds, isEmpty);
      expect(outcome.easyCount, 4);
    });

    test('with nothing deferred, the sitting was already complete', () {
      // _finish() clearing storage should make this unreachable in
      // practice, but the function itself must still answer safely.
      final outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(firstPassJudgedIds: [1, 2, 3, 4, 5, 6]),
      );

      expect(outcome, isNull);
    });
  });

  group('content changed between sittings', () {
    test('a different order at the front invalidates the save', () {
      // Same ids, but 2 and 1 are no longer in the order they were judged -
      // the saved indices can no longer be trusted.
      final reordered = [_q(2), _q(1), _q(3), _q(4), _q(5), _q(6)];

      final outcome = resolveReplayOutcome(
        reordered,
        const ReplayProgress(firstPassJudgedIds: [1, 2]),
      );

      expect(outcome, isNull);
    });

    test('fewer questions than were judged invalidates the save', () {
      final shortened = lesson.take(2).toList(); // only ids 1, 2

      final outcome = resolveReplayOutcome(
        shortened,
        const ReplayProgress(firstPassJudgedIds: [1, 2, 3]),
      );

      expect(outcome, isNull);
    });

    test('a deferred id removed from the lesson is dropped, not kept dangling', () {
      // Judged 1..4 with 2 deferred, but question 2 no longer exists.
      final withoutTwo = [_q(1), _q(3), _q(4), _q(5), _q(6)];

      final outcome = resolveReplayOutcome(
        withoutTwo,
        const ReplayProgress(
          firstPassJudgedIds: [1, 3, 4],
          reviewQueueIds: [2],
        ),
      );

      // The prefix [1, 3, 4] still matches withoutTwo's first three ids, so
      // the first pass itself is still valid; only the stale review id 2 is
      // dropped rather than carried into `nextIds` as a question that no
      // longer exists.
      expect(outcome, isNotNull);
      expect(outcome!.reviewQueueIds, isEmpty);
    });

    test('an empty save is simply nothing in progress', () {
      expect(resolveReplayOutcome(lesson, ReplayProgress.empty), isNull);
    });
  });

  group('the exit-and-return cycle a student actually experiences', () {
    test('two separate interruptions both resume correctly in sequence', () {
      // Sitting 1: judges 1 and 2 (one deferred), then exits.
      var outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(firstPassJudgedIds: [1, 2], reviewQueueIds: [2]),
      );
      expect(outcome!.nextIds, [3, 4, 5, 6]);

      // Sitting 2: the app persisted 3 more judged (4 deferred too), exits
      // again before finishing the first pass.
      outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(
          firstPassJudgedIds: [1, 2, 3, 4],
          reviewQueueIds: [2, 4],
        ),
      );
      expect(outcome!.kind, ReplayOutcomeKind.firstPass);
      expect(outcome.nextIds, [5, 6]);
      expect(outcome.reviewQueueIds, [2, 4]);

      // Sitting 3: the first pass is finally complete; review (2 and 4) is
      // what is left, restarted whole rather than mid-way.
      outcome = resolveReplayOutcome(
        lesson,
        const ReplayProgress(
          firstPassJudgedIds: [1, 2, 3, 4, 5, 6],
          reviewQueueIds: [2, 4],
        ),
      );
      expect(outcome!.kind, ReplayOutcomeKind.reviewTail);
      expect(outcome.nextIds, [2, 4]);
    });
  });
}
