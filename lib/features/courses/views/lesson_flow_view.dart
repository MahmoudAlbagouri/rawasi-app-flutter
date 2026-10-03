// lib/features/courses/views/lesson_flow_view.dart
//
// The lesson study cycle, one question at a time:
//
//   question → (إظهار الإجابة) → answer → سهل / جيد
//   ... every "جيد" goes to a review queue ...
//   → مراجعة الأسئلة → convert each to سهل → lesson complete
//
// "سهل" is the only action that reaches the API: it posts
// questions/{id}/complete. "جيد" is deliberately local — the backend records a
// question as done or not done and has no difficulty field — so a question the
// student marked "جيد" stays incomplete server-side until the review pass turns
// it into "سهل". Completing the last one completes the lesson and unlocks the
// next, which is exactly the old workflow's end state.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/auth/views/subscription_view.dart';
import 'package:rawasi_app_n/features/courses/data/course.dart';
import 'package:rawasi_app_n/features/courses/data/courses_repo.dart';
import 'package:rawasi_app_n/features/courses/data/lesson.dart';
import 'package:rawasi_app_n/features/courses/data/lesson_resume.dart';
import 'package:rawasi_app_n/features/contact/data/contact_repo.dart';
import 'package:rawasi_app_n/features/courses/data/question.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

enum _Phase { loading, failed, question, reviewIntro, review, finishing, done }

class LessonFlowView extends StatefulWidget {
  final int lessonId;
  final int courseId;
  final String lessonTitle;

  /// The subject's curriculum figures, passed down from the courses list.
  ///
  /// The completion summary needs `totalLessons` — the FIXED curriculum total
  /// from config/curriculum.php — as its denominator. Counting the lessons
  /// currently uploaded instead told a student who finished the 3 available
  /// lessons of a 39-lesson subject that they were "100% complete", and their
  /// percentage would then FALL as more content landed. Passed in rather than
  /// refetched, since every caller already holds the Course.
  ///
  /// Null only for a course no configured subject claims, which is handled
  /// without ever claiming completion.
  final CourseProgress? courseProgress;

  const LessonFlowView({
    super.key,
    required this.lessonId,
    required this.courseId,
    required this.lessonTitle,
    this.courseProgress,
  });

  @override
  State<LessonFlowView> createState() => _LessonFlowViewState();
}

class _LessonFlowViewState extends State<LessonFlowView>
    with WidgetsBindingObserver {
  final CoursesRepo _repo = CoursesRepo();

  _Phase _phase = _Phase.loading;
  String _error = '';

  /// The questions of the current pass (first the unanswered ones, then, after
  /// the review intro, the ones marked "جيد").
  List<Question> _pass = [];
  int _index = 0;
  bool _answerShown = false;
  bool _busy = false;

  final List<Question> _reviewQueue = [];
  int _easyCount = 0;

  /// What this sitting is working through, and what was already behind the
  /// student when it began. Held whole rather than as loose counters so the
  /// notice, the question number, the tick count and the progress bar are all
  /// driven by one tested object (lesson_resume.dart) and cannot drift apart.
  LessonResume _resume = LessonResume.empty;

  bool get _isResumed => _resume.isResumed;

  /// Where the current question sits IN THE LESSON, counting from one.
  int get _lessonPosition => _resume.positionInLesson(_index);

  /// Time actually spent on screen, per question.
  ///
  /// A monotonic Stopwatch, not wall-clock arithmetic: the device clock can
  /// jump (NTP, timezone, the student changing it) and would poison the total.
  /// It only runs while a question is on screen AND the app is in the
  /// foreground, so a lesson left open in the background adds nothing.
  ///
  /// Milliseconds are banked per question id rather than seconds because a
  /// question can be measured across two passes - seen once, marked "جيد",
  /// then seen again in the review pass - and rounding each leg separately
  /// would quietly shave a second off every pause.
  final Stopwatch _watch = Stopwatch();
  final Map<int, int> _bankedMs = {};

  /// The backend caps a single question at 2 hours (StudentProgressController);
  /// clamp here too so an absurd value never leaves the device.
  static const int _maxQuestionSeconds = 7200;

  /// Course figures for the completion screen.
  List<Lesson> _courseLessons = [];
  Lesson? _nextLesson;

  /// True when the lesson that WOULD have come next is held by the free-plan
  /// allowance rather than by anything the student still has to do.
  ///
  /// [_nextLesson] already excludes it, correctly — it only ever offers an
  /// unlocked lesson. But "no next lesson" and "the next lesson needs a
  /// subscription" look identical on this screen without this, and the moment a
  /// student finishes their last free lesson is exactly when the reason matters.
  bool _nextNeedsSubscription = false;

  /// The paywall is the 15-day free period ending, not the 25% cap.
  bool _trialEnded = false;

  /// Plans -> receipt -> back to the lesson list, which re-reads from the
  /// server what is open now. Nothing is unlocked on the device.
  Future<void> _openSubscription() async {
    await SubscriptionView.open(context);
    if (mounted) Navigator.pop(context);
  }

  Question get _current => _pass[_index];
  bool get _isReviewPass => _phase == _Phase.review;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watch.stop();
    super.dispose();
  }

  /// Stop counting the moment the app leaves the foreground, and pick up again
  /// on return. Stopwatch.stop() keeps what it has, so start() resumes rather
  /// than restarts.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isTimedPhase) _watch.start();
    } else {
      _watch.stop();
    }
  }

  bool get _isTimedPhase =>
      _phase == _Phase.question || _phase == _Phase.review;

  // ---------------------------------------------------------------------------
  // Time on question
  // ---------------------------------------------------------------------------

  /// Begins measuring the question that is now on screen.
  void _startTimingQuestion() {
    _watch
      ..reset()
      ..start();
  }

  /// Folds whatever the stopwatch holds into [questionId]'s running total and
  /// stops it. Safe to call twice - the second call banks zero.
  void _bankTime(int questionId) {
    _bankedMs[questionId] =
        (_bankedMs[questionId] ?? 0) + _watch.elapsedMilliseconds;
    _watch
      ..stop()
      ..reset();
  }

  /// Seconds to report for [questionId], clamped to what the API accepts.
  int _durationFor(int questionId) => ((_bankedMs[questionId] ?? 0) / 1000)
      .round()
      .clamp(0, _maxQuestionSeconds);

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = '';
    });
    try {
      final questions = await _repo.fetchQuestions(widget.lessonId);
      if (!mounted) return;

      if (questions.isEmpty) {
        await _finish();
        return;
      }

      // Pick up where the student left off rather than restarting at question
      // one. The rule, and why a fully-completed lesson still replays from the
      // start, is in lesson_resume.dart.
      final resume = resumeLesson(questions);

      setState(() {
        _resume = resume;
        _pass = resume.questions;
        _index = 0;
        _easyCount = 0;
        _reviewQueue.clear();
        _answerShown = false;
        _phase = _Phase.question;
      });
      _startTimingQuestion();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiError ? e.message : 'فشل تحميل أسئلة الدرس';
        _phase = _Phase.failed;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _markEasy() async {
    if (_busy) return;
    final question = _current;
    // Stop the clock before the request: network time is not study time.
    _bankTime(question.questionId);

    setState(() => _busy = true);
    try {
      await _repo.completeQuestion(
        question.questionId,
        // A question already completed before this run is a replay, and the
        // backend records replays as no-ops by design - so there is nothing
        // for a duration to attach to. Omitting it keeps the request honest
        // instead of sending time that will be silently dropped.
        durationSeconds: question.isCompleted
            ? null
            : _durationFor(question.questionId),
      );
      if (!mounted) return;
      setState(() => _easyCount++);
      await _advance();
    } catch (e) {
      if (!mounted) return;
      _snack(e is ApiError ? e.message : 'تعذّر حفظ إجابتك، حاول مرة أخرى');
      // The student stays on this question to retry; its banked time is kept
      // and the clock resumes, so a failed attempt costs them nothing.
      _watch.start();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markGood() async {
    if (_busy) return;
    // Not sent yet - "جيد" never reaches the API. The time is banked so that
    // when the review pass turns this question into "سهل" both sittings count.
    _bankTime(_current.questionId);
    _reviewQueue.add(_current);
    await _advance();
  }

  Future<void> _advance() async {
    if (_index + 1 < _pass.length) {
      setState(() {
        _index++;
        // The review pass shows the answer with the question; the first pass
        // hides it again for the next question.
        _answerShown = _isReviewPass;
      });
      _startTimingQuestion();
      return;
    }

    if (_reviewQueue.isEmpty) {
      await _finish();
      return;
    }

    setState(() => _phase = _Phase.reviewIntro);
  }

  void _startReview() {
    setState(() {
      _pass = List.of(_reviewQueue);
      _reviewQueue.clear();
      _index = 0;
      _answerShown = true;
      _phase = _Phase.review;
    });
    _startTimingQuestion();
  }

  Future<void> _finish() async {
    _watch.stop();
    setState(() => _phase = _Phase.finishing);
    try {
      final lessons = await _repo.fetchLessons(widget.courseId);
      if (!mounted) return;
      _courseLessons = lessons;
      _nextLesson = lessons
          .where(
            (l) => l.id != widget.lessonId && !l.isCompleted && l.isUnlocked,
          )
          .fold<Lesson?>(
            null,
            (best, l) => best == null || l.order < best.order ? l : best,
          );

      _nextNeedsSubscription =
          _nextLesson == null && lessons.any((l) => l.requiresPayment);
      _trialEnded = lessons.any((l) => l.isTrialEndedPaywall);
    } catch (_) {
      // The lesson is already completed server-side; stats are a nice-to-have.
    }
    if (mounted) setState(() => _phase = _Phase.done);
  }

  Future<void> _addToLibrary() async {
    try {
      await LibraryRepo().addToLibrary(
        courseId: widget.courseId,
        questionId: _current.questionId,
      );
      if (!mounted) return;
      _snack('تمت إضافة السؤال إلى المكتبة', success: true);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success600 : AppColors.error600,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: _body()),
    );
  }

  String get _appBarTitle => switch (_phase) {
    // The review pass counts its own queue: those ARE all the questions
    // being reviewed, so there is no larger total to measure against.
    _Phase.review => 'مراجعة السؤال ${_index + 1} من ${_pass.length}',
    _Phase.reviewIntro => 'مهمة غير مكتملة',
    _Phase.done => 'تم إنهاء الدرس',
    _ => widget.lessonTitle,
  };

  Widget _body() {
    switch (_phase) {
      case _Phase.loading:
      case _Phase.finishing:
        return const Center(child: CircularProgressIndicator());
      case _Phase.failed:
        return _failed();
      case _Phase.question:
      case _Phase.review:
        return _questionPage();
      case _Phase.reviewIntro:
        return _reviewIntroPage();
      case _Phase.done:
        return _completionPage();
    }
  }

  Widget _failed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error500),
            const Gap(16),
            CustomText(
              text: _error,
              color: AppColors.gray800,
              size: 15,
              align: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Page 1 (question) and page 2 (answer) share this scaffold — page 2 is the
  /// same card with the answer and the سهل/جيد actions revealed.
  Widget _questionPage() {
    final q = _current;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              // Shown only on the first pass of a resumed sitting. The counters
              // below it are relative to what is LEFT, so without this line
              // "السؤال 1 من 15" of a 20-question lesson looks like lost work.
              if (_isResumed && !_isReviewPass) ...[
                _resumeNotice(),
                const Gap(12),
              ],
              _counters(),
              const Gap(12),
              _progressBar(),
              const Gap(12),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary100),
                      ),
                      child: CustomText(
                        text: q.typeLabel,
                        color: AppColors.brandPrimary,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    CustomText(
                      // Numbered against the whole lesson, not against what is
                      // left of it, so this line and the resume notice above
                      // tell the student the same story.
                      text: _isReviewPass
                          ? 'مراجعة ${_index + 1} من ${_pass.length}'
                          : 'السؤال $_lessonPosition من ${_resume.total}',
                      color: AppColors.gray600,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
                const Gap(16),
                CustomText(
                  text: 'السؤال:',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                const Gap(8),
                _panel(q.question),
                if (_answerShown) ...[
                  const Gap(20),
                  CustomText(
                    text: 'الإجابة:',
                    color: AppColors.gray900,
                    size: 15,
                    weight: FontWeight.bold,
                  ),
                  const Gap(8),
                  _panel(
                    q.answer.isEmpty
                        ? 'لا توجد إجابة مسجلة لهذا السؤال.'
                        : q.answer,
                    tinted: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        _questionActions(),
      ],
    );
  }

  Widget _panel(String text, {bool tinted = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? AppColors.success50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tinted
              ? AppColors.success500.withOpacity(0.35)
              : AppColors.gray200,
        ),
      ),
      child: CustomText(text: text, color: AppColors.gray800, size: 15),
    );
  }

  /// سهل / جيد / المكتبة — mirrors the old answer screen's action row.
  Widget _questionActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: AppColors.gray200.withOpacity(0.6), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_answerShown)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _answerShown = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'إظهار الإجابة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (_isReviewPass)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _markEasy,
                icon: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'تحويل هذا السؤال إلى "سهل"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  disabledBackgroundColor: AppColors.gray300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _markEasy,
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'سهل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success600,
                      disabledBackgroundColor: AppColors.gray300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _markGood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      disabledBackgroundColor: AppColors.gray300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'جيد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (_answerShown) ...[
            const Gap(6),
            TextButton.icon(
              onPressed: _addToLibrary,
              icon: const Icon(Icons.star_border, size: 20),
              label: const Text('حفظ كسؤال مفضل في المكتبة'),
              style: TextButton.styleFrom(foregroundColor: AppColors.gray700),
            ),
          ],
          // Available on every question, answer shown or not: a student who
          // cannot make sense of the question itself is exactly who needs to
          // ask about it, and making them reveal the answer first would be a
          // strange toll to charge for asking.
          TextButton.icon(
            onPressed: _openFeedbackSheet,
            icon: const Icon(Icons.flag_outlined, size: 20),
            label: const Text('ملاحظة أو استفسار عن السؤال'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  /// "تم استئناف الدرس — أكملت 5 من 20 سؤالاً".
  Widget _resumeNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success500.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: AppColors.success700,
            size: 20,
          ),
          const Gap(10),
          Expanded(
            child: CustomText(
              text:
                  'تم استئناف الدرس — أكملت ${_resume.alreadyDone}'
                  ' من ${_resume.total} سؤالاً',
              color: AppColors.success700,
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Lets the student write a note about the question in front of them.
  ///
  /// Posted to /contact-support with the question attached, so it lands in the
  /// inbox an admin already reads and replies to, and the reply comes back in
  /// the student's own list of past messages. A separate feedback table would
  /// have needed its own dashboard screen before a single note reached anyone.
  Future<void> _openFeedbackSheet() async {
    final controller = TextEditingController();
    final questionId = _current.questionId;
    var sending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          // Lifts the field clear of the keyboard; without this the send button
          // sits under it on a short screen.
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    color: AppColors.brandPrimary,
                    size: 22,
                  ),
                  const Gap(10),
                  Expanded(
                    child: CustomText(
                      text: 'ملاحظة على هذا السؤال',
                      color: AppColors.gray900,
                      size: 16,
                      weight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, color: AppColors.gray500),
                  ),
                ],
              ),
              const Gap(4),
              CustomText(
                text:
                    'اكتب استفسارك أو أبلغ عن خطأ في السؤال أو إجابته، وسيصلك الرد في صفحة تواصل معنا.',
                color: AppColors.gray600,
                size: 12,
              ),
              const Gap(14),
              TextField(
                controller: controller,
                maxLines: 5,
                minLines: 3,
                // Matches the server's max:2000 so the student is stopped by the
                // field rather than by a rejected request.
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'مثال: الإجابة المسجلة لهذا السؤال غير صحيحة.',
                  filled: true,
                  fillColor: AppColors.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                ),
              ),
              const Gap(4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;

                          setSheetState(() => sending = true);
                          try {
                            await ContactRepo().sendQuestionFeedback(
                              questionId: questionId,
                              message: text,
                            );
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            if (mounted) {
                              _snack(
                                'تم إرسال ملاحظتك، شكرًا لك',
                                success: true,
                              );
                            }
                          } catch (e) {
                            if (!sheetContext.mounted) return;
                            setSheetState(() => sending = false);
                            // Reported inside the sheet, not behind it: the
                            // student still has their text and can retry.
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e is ApiError
                                      ? e.message
                                      : 'تعذّر إرسال الملاحظة',
                                ),
                                backgroundColor: AppColors.error600,
                              ),
                            );
                          }
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: Text(sending ? 'جارٍ الإرسال...' : 'إرسال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
  }

  /// "3 ↻ | 10 | 1 ✓" — review queue, remaining in this pass, done so far.
  Widget _counters() {
    Widget item(IconData icon, int value, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const Gap(4),
        CustomText(
          text: '$value',
          color: color,
          size: 14,
          weight: FontWeight.bold,
        ),
      ],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item(Icons.refresh, _reviewQueue.length, AppColors.brandPrimary),
        item(
          Icons.pending_outlined,
          _pass.length - _index - 1,
          AppColors.gray600,
        ),
        // Questions already behind the student in this LESSON, not only in this
        // sitting — otherwise a resumed lesson showed a tick count of 0 beside
        // a notice saying two were already done.
        item(
          Icons.check_circle_outline,
          _isReviewPass ? _easyCount : _resume.alreadyDone + _easyCount,
          AppColors.success600,
        ),
      ],
    );
  }

  Widget _progressBar() {
    // One segment per question, like the old dotted indicator. Segments stay
    // legible at any count because they share the row width.
    //
    // On the first pass the bar spans the whole LESSON, with the questions
    // completed in earlier sittings already filled in. Drawing only what is
    // left would restart the bar from empty every time a student came back,
    // which is the visual version of the same "it forgot my progress" problem.
    final total = _isReviewPass ? _pass.length : _resume.total;
    final offset = _isReviewPass ? 0 : _resume.alreadyDone;

    return Row(
      children: List.generate(total, (i) {
        final done = i < offset + _index;
        final current = i == offset + _index;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 5,
            decoration: BoxDecoration(
              color: current
                  ? AppColors.brandPrimary
                  : done
                  ? AppColors.success500
                  : AppColors.gray200,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  /// Shown once the first pass ends with questions still marked "جيد".
  Widget _reviewIntroPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Gap(12),
          Icon(Icons.pending_actions, size: 72, color: AppColors.brandPrimary),
          const Gap(16),
          CustomText(
            text: 'مهمة غير مكتملة',
            color: AppColors.brandPrimary,
            size: 20,
            weight: FontWeight.bold,
          ),
          const Gap(20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary100),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                    const Gap(8),
                    CustomText(
                      text: 'ملاحظة هامة',
                      color: AppColors.brandPrimary,
                      size: 15,
                      weight: FontWeight.bold,
                    ),
                  ],
                ),
                const Gap(10),
                CustomText(
                  text:
                      'لابد من مراجعة الأسئلة التي تم اختيارها "جيد" وإعادة اختيارها "سهل" لكي تكتمل المهمة بنجاح',
                  color: AppColors.gray700,
                  size: 14,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  value: _easyCount,
                  label: 'سهل',
                  color: AppColors.success600,
                  background: AppColors.success50,
                ),
              ),
              const Gap(12),
              Expanded(
                child: _statCard(
                  value: _reviewQueue.length,
                  label: 'جيد',
                  color: AppColors.brandPrimary,
                  background: AppColors.primary50,
                  highlighted: true,
                ),
              ),
            ],
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startReview,
              icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
              label: Text(
                'مراجعة الأسئلة (${_reviewQueue.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const Gap(12),
          CustomText(
            text: 'ستتمكن من إكمال المهمة بعد تحويل جميع الأسئلة إلى "سهل"',
            color: AppColors.gray600,
            size: 13,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required int value,
    required String label,
    required Color color,
    required Color background,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? color : Colors.transparent,
          width: highlighted ? 1.5 : 0,
        ),
      ),
      child: Column(
        children: [
          CustomText(
            text: '$value',
            color: color,
            size: 26,
            weight: FontWeight.bold,
          ),
          const Gap(4),
          CustomText(
            text: label,
            color: color,
            size: 14,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  /// Final screen: lesson done, next lesson unlocked, and where the student now
  /// stands in this course.
  Widget _completionPage() {
    // How many lessons of this subject exist so far. NOT the denominator.
    final available = _courseLessons.length;
    final completed = _courseLessons.where((l) => l.isCompleted).length;

    // The curriculum figure is the denominator, so the percentage means
    // "of the subject" and stays put as more lessons are uploaded.
    final curriculumTotal = widget.courseProgress?.totalLessons;
    final total = curriculumTotal ?? available;

    final remaining = (total - completed).clamp(0, total);
    final percent = total == 0 ? 0 : ((completed / total) * 100).round();

    // The celebration fires ONLY against the real curriculum total. Exhausting
    // what happens to be uploaded is a different — and right now very common —
    // state, and saying "you finished the subject" there would be false.
    final finishedSubject =
        curriculumTotal != null && completed >= curriculumTotal;
    final finishedAvailable =
        !finishedSubject && available > 0 && completed >= available;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Gap(16),
          Icon(Icons.verified, size: 84, color: AppColors.success600),
          const Gap(16),
          CustomText(
            text: 'أحسنت! تم إنهاء الدرس بنجاح',
            color: AppColors.gray900,
            size: 20,
            weight: FontWeight.bold,
            align: TextAlign.center,
          ),
          const Gap(8),
          CustomText(
            text: widget.lessonTitle,
            color: AppColors.gray600,
            size: 14,
            align: TextAlign.center,
          ),
          const Gap(24),
          if (total > 0) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                children: [
                  CustomText(
                    text: 'تقدمك في هذه المادة',
                    color: AppColors.gray900,
                    size: 15,
                    weight: FontWeight.bold,
                  ),
                  const Gap(14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : completed / total,
                      minHeight: 10,
                      color: AppColors.success600,
                      backgroundColor: AppColors.gray200,
                    ),
                  ),
                  const Gap(10),
                  CustomText(
                    text: 'اكتمل $percent% — $completed من $total درسًا',
                    color: AppColors.gray700,
                    size: 14,
                  ),
                  const Gap(6),
                  CustomText(
                    text: finishedSubject
                        ? 'أكملت جميع دروس هذه المادة 🎉'
                        : finishedAvailable
                        ? 'أنهيت كل الدروس المتاحة حاليًا — والمزيد في الطريق'
                        : 'المتبقي: $remaining درسًا',
                    color: finishedSubject
                        ? AppColors.success700
                        : finishedAvailable
                        ? AppColors.brandPrimary
                        : AppColors.gray600,
                    size: 14,
                    weight: FontWeight.w600,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Gap(16),
          ],
          if (_nextLesson == null && _nextNeedsSubscription)
            // Tappable: the paywall leads to the plans. Afterwards we go back
            // to the lesson list, which re-reads what the server now opens.
            GestureDetector(
              onTap: _openSubscription,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.brandPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: AppColors.warning700),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: _trialEnded
                                ? 'انتهت الفترة المجانية (15 يومًا)'
                                : 'انتهى الحد المجاني من هذه المادة',
                            color: AppColors.gray900,
                            size: 14,
                            weight: FontWeight.bold,
                          ),
                          const Gap(4),
                          CustomText(
                            text: 'اشترك لمتابعة باقي الدروس',
                            color: AppColors.brandPrimary,
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
            ),
          if (_nextLesson != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success500.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_open, color: AppColors.success700),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: 'الدرس التالي متاح لك',
                          color: AppColors.success700,
                          size: 14,
                          weight: FontWeight.bold,
                        ),
                        const Gap(4),
                        CustomText(
                          text: _nextLesson!.title,
                          color: AppColors.gray800,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Gap(24),
          if (_nextLesson != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final next = _nextLesson!;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonFlowView(
                        lessonId: next.id,
                        courseId: widget.courseId,
                        lessonTitle: next.title,
                        courseProgress: widget.courseProgress,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'ابدأ الدرس التالي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const Gap(10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.gray300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'العودة إلى قائمة الدروس',
                style: TextStyle(color: AppColors.gray800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
