// lib/features/courses/data/lesson_resume.dart
//
// Deciding what a sitting of a lesson should actually ask.
//
// THE BUG THIS FIXES: the lesson flow always started at question 1. A student
// who answered 5 of 20 and then lost the app, the network or their patience had
// to work back through those 5 before reaching anything new — and on a long
// lesson that is enough to make them give up on it.
//
// Nothing was ever lost server-side. Every "سهل" writes a student_progress row,
// and the questions endpoint reports `is_completed` per question. The flow
// simply ignored it.

import 'package:rawasi_app_n/features/courses/data/question.dart';

/// What to ask in this sitting, and what was already done before it.
class LessonResume {
  /// The questions to work through now.
  final List<Question> questions;

  /// How many were already complete when this sitting began. Zero when starting
  /// fresh or replaying.
  final int alreadyDone;

  /// The lesson's full question count, for the notice ("5 of 20").
  final int total;

  const LessonResume({
    required this.questions,
    required this.alreadyDone,
    required this.total,
  });

  /// True when this sitting picked up part-finished work.
  bool get isResumed => alreadyDone > 0;
}

/// Picks up where the student left off.
///
/// PARTLY DONE → carry on with what is outstanding.
///
/// FULLY DONE → replay the whole lesson from the start. That is not a fallback,
/// it is the explicit "حل مرة أخرى" action offered on a completed lesson in the
/// lesson list, and it has to keep working.
///
/// The two are told apart by whether anything is outstanding rather than by a
/// stored flag: an empty remainder IS the completed case, so one condition
/// covers both and they cannot disagree.
///
/// NOTHING DONE → the whole lesson, with no resume notice, because there is
/// nothing to explain.
///
/// Replays stay harmless whichever branch runs: completing an already-recorded
/// question is a no-op server-side, so progress, statistics, streaks and lesson
/// unlocks are untouched by one.
LessonResume resumeLesson(List<Question> questions) {
  final remaining = questions.where((q) => !q.isCompleted).toList();

  // Every question done: a replay was asked for.
  if (remaining.isEmpty) {
    return LessonResume(
      questions: questions,
      alreadyDone: 0,
      total: questions.length,
    );
  }

  // Nothing done: a fresh start, which needs no explaining.
  if (remaining.length == questions.length) {
    return LessonResume(
      questions: questions,
      alreadyDone: 0,
      total: questions.length,
    );
  }

  return LessonResume(
    questions: remaining,
    alreadyDone: questions.length - remaining.length,
    total: questions.length,
  );
}
