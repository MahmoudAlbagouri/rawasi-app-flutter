import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/courses/data/lesson_resume.dart';
import 'package:rawasi_app_n/features/courses/data/question.dart';

/// THE BUG: the lesson flow always started at question 1. A student who
/// answered 5 of 20 and then lost the app, the network or their patience had to
/// work back through those 5 before reaching anything new.
///
/// Nothing was ever lost server-side — every "سهل" writes a student_progress
/// row and the questions endpoint reports `is_completed` per question. The flow
/// just ignored it.
///
/// The one thing that must NOT regress while fixing it: a fully completed lesson
/// still replays from the start, because that is the explicit "حل مرة أخرى"
/// action offered on a completed lesson.
List<Question> _lesson({required int total, required int done}) => List.generate(
      total,
      (i) => Question(
        questionId: i + 1,
        lessonId: 7,
        type: 'definitions',
        question: 'سؤال ${i + 1}',
        answer: 'إجابة ${i + 1}',
        isCompleted: i < done,
      ),
    );

void main() {
  group('a part-finished lesson', () {
    test('carries on with what is outstanding', () {
      final resume = resumeLesson(_lesson(total: 20, done: 5));

      expect(resume.questions.length, 15);
      expect(resume.alreadyDone, 5);
      expect(resume.total, 20);
      expect(resume.isResumed, isTrue);
    });

    test('asks none of the questions already answered', () {
      final resume = resumeLesson(_lesson(total: 20, done: 5));

      expect(
        resume.questions.any((q) => q.isCompleted),
        isFalse,
        reason: 'a resumed sitting must not re-ask completed work',
      );
      // The first outstanding one, not the first in the lesson.
      expect(resume.questions.first.questionId, 6);
    });

    test('one answered of many is still a resume', () {
      final resume = resumeLesson(_lesson(total: 20, done: 1));

      expect(resume.questions.length, 19);
      expect(resume.alreadyDone, 1);
      expect(resume.isResumed, isTrue);
    });

    test('all but one answered leaves exactly that one', () {
      final resume = resumeLesson(_lesson(total: 20, done: 19));

      expect(resume.questions.length, 1);
      expect(resume.questions.single.questionId, 20);
      expect(resume.alreadyDone, 19);
    });

    test('completed questions scattered through the lesson are all skipped', () {
      // Completion is per question, and the review pass means they do not have
      // to be finished in order. Filtering by position instead of by the flag
      // would re-ask some and skip others.
      final questions = [
        Question(questionId: 1, lessonId: 7, type: 't', question: 'a', answer: 'a', isCompleted: true),
        Question(questionId: 2, lessonId: 7, type: 't', question: 'b', answer: 'b', isCompleted: false),
        Question(questionId: 3, lessonId: 7, type: 't', question: 'c', answer: 'c', isCompleted: true),
        Question(questionId: 4, lessonId: 7, type: 't', question: 'd', answer: 'd', isCompleted: false),
      ];

      final resume = resumeLesson(questions);

      expect(resume.questions.map((q) => q.questionId), [2, 4]);
      expect(resume.alreadyDone, 2);
    });
  });

  group('a fresh lesson', () {
    test('asks everything, with nothing to explain', () {
      final resume = resumeLesson(_lesson(total: 20, done: 0));

      expect(resume.questions.length, 20);
      expect(resume.alreadyDone, 0);
      expect(
        resume.isResumed,
        isFalse,
        reason: 'the resume notice must not appear on a first sitting',
      );
    });
  });

  group('a completed lesson', () {
    test('replays the whole lesson, which is what حل مرة أخرى asks for', () {
      final resume = resumeLesson(_lesson(total: 20, done: 20));

      expect(resume.questions.length, 20);
      expect(resume.questions.first.questionId, 1);
      expect(
        resume.isResumed,
        isFalse,
        reason: 'a replay is not a resume and must not claim to be one',
      );
    });

    test('a one-question completed lesson replays rather than emptying', () {
      // The degenerate case: filtering first and asking questions later would
      // hand the flow an empty list and skip straight to the summary.
      final resume = resumeLesson(_lesson(total: 1, done: 1));

      expect(resume.questions.length, 1);
    });
  });

  group('the number the student is shown', () {
    // THE REPORTED BUG: resuming a lesson with 2 of 18 done showed
    // "السؤال 1 من 16" directly under "أكملت 2 من 18 سؤالاً". The resume was
    // working — those 2 were not re-asked — but the counter renumbered against
    // the 16 remaining, so it read as "it started me at question 1 again".
    test('continues the lesson numbering, it does not restart it', () {
      final resume = resumeLesson(_lesson(total: 18, done: 2));

      // First question of the sitting is question 3 OF THE LESSON.
      expect(resume.positionInLesson(0), 3);
      expect(resume.total, 18);
      expect(resume.alreadyDone, 2);
    });

    test('runs to the lesson total, never past it', () {
      final resume = resumeLesson(_lesson(total: 18, done: 2));

      // Last question of the sitting is the 18th of the lesson.
      expect(resume.positionInLesson(resume.questions.length - 1), 18);
    });

    test('a fresh lesson numbers from one, exactly as before', () {
      final resume = resumeLesson(_lesson(total: 18, done: 0));

      expect(resume.positionInLesson(0), 1);
      expect(resume.total, 18);
    });

    test('a replay numbers from one too', () {
      final resume = resumeLesson(_lesson(total: 18, done: 18));

      expect(resume.positionInLesson(0), 1);
      expect(resume.positionInLesson(17), 18);
    });

    test('the number and the resume notice always agree', () {
      // The contradiction the student saw: the notice said 2 of 18 were done,
      // the counter said this was question 1 of 16. Whatever the figures, the
      // first question of a sitting must be the one after the last completed.
      for (final done in [0, 1, 2, 5, 17]) {
        final resume = resumeLesson(_lesson(total: 18, done: done));
        expect(
          resume.positionInLesson(0),
          resume.alreadyDone + 1,
          reason: 'with \$done already done',
        );
      }
    });
  });

  group('edge cases', () {
    test('an empty lesson stays empty rather than throwing', () {
      final resume = resumeLesson(const []);

      expect(resume.questions, isEmpty);
      expect(resume.total, 0);
      expect(resume.isResumed, isFalse);
    });

    test('the original list is never mutated', () {
      // The caller keeps using it for the course figures on the summary screen.
      final questions = _lesson(total: 10, done: 4);
      resumeLesson(questions);

      expect(questions.length, 10);
    });
  });

  group('isFullReplay', () {
    // resumeLesson() cannot tell a caller this on its own - its return shape
    // is identical for "nothing done" and "a replay is starting". This is the
    // one thing lesson_flow_view.dart needs that resumeLesson()'s shape alone
    // does not give it, to know when to even look for a saved replay sitting.
    test('every question completed is a replay', () {
      expect(isFullReplay(_lesson(total: 20, done: 20)), isTrue);
    });

    test('a fresh lesson is not a replay', () {
      expect(isFullReplay(_lesson(total: 20, done: 0)), isFalse);
    });

    test('a part-finished lesson is not a replay', () {
      expect(isFullReplay(_lesson(total: 20, done: 19)), isFalse);
    });

    test('an empty lesson is not a replay', () {
      // Otherwise `questions.every(...)` on an empty list (vacuously true)
      // would call a lesson with nothing uploaded yet a "replay".
      expect(isFullReplay(const []), isFalse);
    });

    test('a single completed question is a replay', () {
      expect(isFullReplay(_lesson(total: 1, done: 1)), isTrue);
    });
  });
}
