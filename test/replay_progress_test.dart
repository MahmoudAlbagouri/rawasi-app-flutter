import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/replay_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// THE BUG THIS FIXES: unlike a first attempt, a REPLAY ("حل مرة أخرى") has
/// no server-side signal the app can read to know how far it got - every
/// question is already `is_completed = true` before the replay even starts,
/// and stays that way regardless of how many of them are re-solved. So a
/// student who exited midway through a replay came back to the whole lesson
/// restarting from question one, same as if they had done nothing at all.
///
/// ReplayProgress/ReplayProgressStore is the one piece of state that makes
/// this resumable: a small local record of which questions this replay's
/// first pass has already judged, scoped to the student + lesson, read back
/// the next time the lesson is opened.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('an empty record', () {
    test('reports nothing in progress', () {
      expect(ReplayProgress.empty.isInProgress, isFalse);
    });

    test('a record with ids in progress reports so', () {
      expect(
        const ReplayProgress(firstPassJudgedIds: [1]).isInProgress,
        isTrue,
      );
    });
  });

  group('round-tripping through JSON', () {
    test('both lists survive encode/decode', () {
      const original = ReplayProgress(
        firstPassJudgedIds: [1, 2, 3, 5],
        reviewQueueIds: [2, 5],
      );

      final restored = ReplayProgress.fromJson(original.toJson());

      expect(restored.firstPassJudgedIds, [1, 2, 3, 5]);
      expect(restored.reviewQueueIds, [2, 5]);
    });

    test('an empty record round-trips to an empty record', () {
      final restored = ReplayProgress.fromJson(ReplayProgress.empty.toJson());

      expect(restored.isInProgress, isFalse);
    });

    test('garbage where a list should be decodes as empty, not a crash', () {
      final restored = ReplayProgress.fromJson({
        'first_pass_judged_ids': 'not a list',
        'review_queue_ids': null,
      });

      expect(restored.firstPassJudgedIds, isEmpty);
      expect(restored.reviewQueueIds, isEmpty);
    });
  });

  group('ReplayProgressStore', () {
    test('loading with nothing saved returns empty, not an error', () async {
      final loaded = await ReplayProgressStore.load('token-a', 101);

      expect(loaded.isInProgress, isFalse);
    });

    test('what is saved is what comes back', () async {
      const progress = ReplayProgress(
        firstPassJudgedIds: [10, 11, 12],
        reviewQueueIds: [11],
      );

      await ReplayProgressStore.save('token-a', 101, progress);
      final loaded = await ReplayProgressStore.load('token-a', 101);

      expect(loaded.firstPassJudgedIds, [10, 11, 12]);
      expect(loaded.reviewQueueIds, [11]);
    });

    test('clearing removes it - the next load starts fresh', () async {
      await ReplayProgressStore.save(
        'token-a',
        101,
        const ReplayProgress(firstPassJudgedIds: [1]),
      );
      await ReplayProgressStore.clear('token-a', 101);

      final loaded = await ReplayProgressStore.load('token-a', 101);
      expect(loaded.isInProgress, isFalse);
    });

    test('different lessons for the same student never collide', () async {
      await ReplayProgressStore.save(
        'token-a',
        101,
        const ReplayProgress(firstPassJudgedIds: [1]),
      );
      await ReplayProgressStore.save(
        'token-a',
        202,
        const ReplayProgress(firstPassJudgedIds: [9]),
      );

      expect(
        (await ReplayProgressStore.load('token-a', 101)).firstPassJudgedIds,
        [1],
      );
      expect(
        (await ReplayProgressStore.load('token-a', 202)).firstPassJudgedIds,
        [9],
      );
    });

    test('a different student never resumes this one\'s replay', () {
      // THE RULE: scoped by token + lesson, so signing in as someone else on
      // the same device cannot pick up where a different student stopped.
      return Future(() async {
        await ReplayProgressStore.save(
          'token-a',
          101,
          const ReplayProgress(firstPassJudgedIds: [1, 2, 3]),
        );

        final asSomeoneElse = await ReplayProgressStore.load('token-b', 101);
        expect(asSomeoneElse.isInProgress, isFalse);
      });
    });

    test('clearing one lesson leaves another student/lesson untouched', () async {
      await ReplayProgressStore.save(
        'token-a',
        101,
        const ReplayProgress(firstPassJudgedIds: [1]),
      );
      await ReplayProgressStore.save(
        'token-a',
        202,
        const ReplayProgress(firstPassJudgedIds: [9]),
      );

      await ReplayProgressStore.clear('token-a', 101);

      expect((await ReplayProgressStore.load('token-a', 101)).isInProgress, isFalse);
      expect((await ReplayProgressStore.load('token-a', 202)).firstPassJudgedIds, [9]);
    });
  });
}
