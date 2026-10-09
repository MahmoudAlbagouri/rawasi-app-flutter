// lib/features/courses/data/replay_progress.dart
//
// Remembers how far into a REPLAY ("حل مرة أخرى") a student got, so exiting
// midway through one and coming back continues it instead of starting the
// lesson over from question one.
//
// WHY THIS CANNOT COME FROM THE SERVER, UNLIKE THE FIRST ATTEMPT. The first
// attempt's resume (lesson_resume.dart) reads `is_completed` per question,
// which the server already tracks via student_progress — nothing extra is
// needed, and nothing extra should be added there (the server already
// knows). A REPLAY answers questions that are ALREADY `is_completed = true`;
// completing one again is recorded only as a re-solve in question_attempts
// (insert-only, for points/mastery) — student_progress itself never changes.
// So once a lesson is fully done, every fetch of its questions looks
// identical whether a replay has just started or is nearly finished: the
// server has nothing to read that would tell the two apart. This is
// therefore local-only, and only for the replay case — the first attempt's
// resume is untouched.
//
// WHAT IS NOT RESUMED. Only the first pass (سهل/جيد over every question) is
// remembered. If a student exits during the REVIEW pass (converting the
// "جيد" questions to "سهل"), the next visit restarts that short tail from
// its beginning rather than resuming mid-review — it is normally a handful
// of questions whose answers are already on screen, so repeating it is a
// small inconvenience next to the one this fixes: losing the whole lesson.
// What is never lost is the first pass itself, however many "جيد" questions
// were deferred — reviewQueueIds is restored exactly even when the first
// pass has to restart its own review tail.
//
// Scoped to the signed-in token + lesson, so a different student signing in
// on the same device never resumes someone else's replay. Nothing here is
// ever sent to the server — it only decides where the app puts the student
// back on screen.

import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:rawasi_app_n/features/courses/data/question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReplayProgress {
  /// Ids judged — "سهل" or "جيد" — in the first pass of this replay, in the
  /// order they were judged.
  final List<int> firstPassJudgedIds;

  /// The subset of [firstPassJudgedIds] marked "جيد" and deferred to review,
  /// in the order they were deferred.
  final List<int> reviewQueueIds;

  const ReplayProgress({
    this.firstPassJudgedIds = const [],
    this.reviewQueueIds = const [],
  });

  static const ReplayProgress empty = ReplayProgress();

  bool get isInProgress => firstPassJudgedIds.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'first_pass_judged_ids': firstPassJudgedIds,
    'review_queue_ids': reviewQueueIds,
  };

  factory ReplayProgress.fromJson(Map<String, dynamic> json) {
    List<int> ints(Object? value) => (value is List)
        ? value.whereType<num>().map((n) => n.toInt()).toList()
        : const [];

    return ReplayProgress(
      firstPassJudgedIds: ints(json['first_pass_judged_ids']),
      reviewQueueIds: ints(json['review_queue_ids']),
    );
  }
}

/// What a saved replay sitting resolves to once checked against the
/// lesson's CURRENT questions.
enum ReplayOutcomeKind {
  /// The first pass still has work left — resume it, trimmed to [nextIds].
  firstPass,

  /// The first pass was finished before the student left. Nothing to resume
  /// IN review (see the class doc on [ReplayProgress]) — [nextIds] is the
  /// full, restored review queue to start fresh.
  reviewTail,
}

class ReplayOutcome {
  final ReplayOutcomeKind kind;

  /// The ids to ask next, in order — the trimmed first-pass remainder for
  /// [ReplayOutcomeKind.firstPass], or the full restored queue for
  /// [ReplayOutcomeKind.reviewTail].
  final List<int> nextIds;

  /// How many of the full lesson are already behind the student in this
  /// sitting's FIRST PASS. Zero for a [ReplayOutcomeKind.reviewTail] outcome
  /// — the resume notice is deliberately scoped to the first pass only, the
  /// same way it already is for an ordinary (non-replay) resumed sitting.
  final int alreadyDone;

  /// Deferred ("جيد") ids still pending review. Empty for a
  /// [ReplayOutcomeKind.reviewTail] outcome, where they are [nextIds]
  /// instead.
  final List<int> reviewQueueIds;

  /// First-pass verdicts that were NOT deferred — i.e. "سهل" — so the caller
  /// can seed its own easy-count correctly.
  final int easyCount;

  const ReplayOutcome({
    required this.kind,
    required this.nextIds,
    required this.alreadyDone,
    required this.reviewQueueIds,
    required this.easyCount,
  });
}

/// The pure half of resuming a replay: given the lesson's CURRENT questions
/// and what was saved, decides what to resume into — or `null` to start an
/// ordinary fresh replay. No I/O, no token, nothing from the widget: every
/// decision that actually needs making, in one place that can be tested on
/// its own (see replay_progress_test.dart), the same way lesson_resume.dart's
/// resumeLesson() is.
ReplayOutcome? resolveReplayOutcome(
  List<Question> questions,
  ReplayProgress saved,
) {
  if (!saved.isInProgress) return null;

  // The saved ids must be exactly the leading run of THIS fetch, in the same
  // order: the first pass always judges `questions` strictly in order, so
  // anything else means the lesson's content changed between sittings
  // (reordered, a question added or removed) and an index into it can no
  // longer be trusted. Safer to drop it than guess.
  final prefix = questions
      .take(saved.firstPassJudgedIds.length)
      .map((q) => q.questionId)
      .toList();
  if (!listEquals(prefix, saved.firstPassJudgedIds)) return null;

  final knownIds = questions.map((q) => q.questionId).toSet();
  final judgedSet = saved.firstPassJudgedIds.toSet();
  // Deferred ids that were not also judged, or no longer exist, cannot be
  // valid questions to review — defensive, should not happen given the
  // prefix check above already passed.
  final reviewIds = saved.reviewQueueIds
      .where((id) => judgedSet.contains(id) && knownIds.contains(id))
      .toList();
  final easyCount = saved.firstPassJudgedIds.length - reviewIds.length;

  if (saved.firstPassJudgedIds.length < questions.length) {
    final remaining = questions
        .where((q) => !judgedSet.contains(q.questionId))
        .map((q) => q.questionId)
        .toList();

    return ReplayOutcome(
      kind: ReplayOutcomeKind.firstPass,
      nextIds: remaining,
      alreadyDone: saved.firstPassJudgedIds.length,
      reviewQueueIds: reviewIds,
      easyCount: easyCount,
    );
  }

  if (reviewIds.isNotEmpty) {
    return ReplayOutcome(
      kind: ReplayOutcomeKind.reviewTail,
      nextIds: reviewIds,
      alreadyDone: 0,
      reviewQueueIds: const [],
      easyCount: easyCount,
    );
  }

  // Fully judged with nothing deferred: this sitting was already complete.
  // _finish() clearing storage should mean this is unreached, but it is not
  // this function's job to clear anything — it only decides, never writes.
  return null;
}

class ReplayProgressStore {
  static String _key(String token, int lessonId) =>
      'replay_progress::$token::$lessonId';

  /// Never throws: a storage fault just means the next sitting starts fresh,
  /// exactly like a student opening the lesson for the very first time.
  static Future<ReplayProgress> load(String token, int lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(token, lessonId));
      if (raw == null) return ReplayProgress.empty;
      return ReplayProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return ReplayProgress.empty;
    }
  }

  static Future<void> save(
    String token,
    int lessonId,
    ReplayProgress progress,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(token, lessonId),
        jsonEncode(progress.toJson()),
      );
    } catch (_) {
      // Worst case the next exit mid-replay is not remembered either — never
      // worth surfacing to the student over.
    }
  }

  static Future<void> clear(String token, int lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(token, lessonId));
    } catch (_) {
      // A stray entry left behind is harmless: it is re-validated against the
      // fetched questions on every load and dropped the moment it does not
      // match, never acted on blindly.
    }
  }
}
