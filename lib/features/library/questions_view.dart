// lib/features/library/questions_view.dart
//
// The library's run-through for one subject, one question at a time:
//
//   page 1 (question)  → إظهار الإجابة → page 2 (question + answer)
//                                         ├─ السؤال التالي
//                                         └─ إزالة السؤال من المكتبة
//   ... after the last one → summary
//
// Mirrors the lesson flow's shape deliberately, so the two feel like the same
// app. It is, however, completely independent of student_progress: nothing
// here reads or writes lesson/course progress, and re-entering a subject as
// often as the student likes changes nothing but the library rows themselves.
// Like the repeatable lessons, repeat runs are not recorded — no attempt
// counters, no new columns.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

enum _Phase { loading, failed, question, done }

class QuestionsView extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const QuestionsView({
    super.key,
    required this.subjectId,
    this.subjectName = 'الأسئلة',
  });

  @override
  State<QuestionsView> createState() => _QuestionsViewState();
}

class _QuestionsViewState extends State<QuestionsView> {
  final LibraryRepo _repo = LibraryRepo();

  _Phase _phase = _Phase.loading;
  String _error = '';

  /// The questions still in the library for this subject, in server order.
  List<ContentItem> _questions = [];
  int _index = 0;

  /// Page 1 vs page 2. The answer is not built at all while this is false —
  /// it is not rendered off-screen or at zero opacity.
  bool _answerShown = false;

  bool _busy = false;

  /// Counters for the summary. Reset on every entry, by construction: this
  /// State is created fresh each time the subject is opened.
  int _removedThisRun = 0;

  /// True when at least one removal happened, so the caller knows to refresh
  /// the subjects list rather than show a stale row.
  bool get _changed => _removedThisRun > 0;

  ContentItem get _current => _questions[_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = '';
    });
    try {
      final items = await _repo.fetchContent(widget.subjectId, 'question');
      if (!mounted) return;
      setState(() {
        _questions = items;
        _index = 0;
        _answerShown = false;
        // An already-empty subject goes straight to the summary rather than
        // showing an empty question page.
        _phase = items.isEmpty ? _Phase.done : _Phase.question;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _phase = _Phase.failed;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _showAnswer() => setState(() => _answerShown = true);

  void _next() {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _answerShown = false;
      });
      return;
    }
    setState(() => _phase = _Phase.done);
  }

  /// Optimistic removal with rollback, then advance automatically.
  ///
  /// No confirm dialog: removal is what the student came here to do, and a
  /// dialog on every card makes a twelve-question pass tedious. The safety net
  /// is an "تراجع" snackbar instead — see [_undoRemoval].
  Future<void> _remove() async {
    if (_busy) return;

    final item = _current;
    final removedIndex = _index;
    final snapshot = List<ContentItem>.from(_questions);

    setState(() {
      _busy = true;
      _questions = List.of(_questions)..removeAt(removedIndex);
      _removedThisRun++;
      // Stay on the same index: the next question has slid into this slot.
      // If the removed one was last, step back onto the new last item.
      if (_index >= _questions.length) _index = _questions.length - 1;
      _answerShown = false;
    });

    try {
      await _repo.removeFromLibrary(
        contentId: item.id,
        courseId: widget.subjectId,
        taskId: item.libraryable.id,
        type: 'question',
      );

      if (!mounted) return;

      // Removing the last one goes straight to the summary.
      if (_questions.isEmpty) {
        setState(() => _phase = _Phase.done);
      }
      _snack(
        'تمت إزالة السؤال من المكتبة',
        action: SnackBarAction(
          label: 'تراجع',
          textColor: AppColors.white,
          onPressed: () => _undoRemoval(item, removedIndex),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Roll back so a network error never silently loses a saved question.
      setState(() {
        _questions = snapshot;
        _index = removedIndex;
        _removedThisRun--;
        _phase = _Phase.question;
      });
      _snack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-saves a question the student has just removed.
  ///
  /// The old library row is gone, so this genuinely re-adds it and the row
  /// comes back with a new id — which is why the list is reloaded rather than
  /// spliced back in with the stale id.
  Future<void> _undoRemoval(ContentItem item, int atIndex) async {
    try {
      await LibraryRepo().addToLibrary(
        courseId: widget.subjectId,
        questionId: item.libraryable.id,
      );
      if (!mounted) return;
      setState(() => _removedThisRun = (_removedThisRun - 1).clamp(0, 1 << 30));
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('تعذّر التراجع، حاول مرة أخرى', isError: true);
    }
  }

  void _snack(String message, {bool isError = false, SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? AppColors.error600 : AppColors.brandSecondary,
          action: action,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Back to the library, telling it whether anything changed.
  void _backToLibrary() => Navigator.pop(context, _changed);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _backToLibrary();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
            onPressed: _backToLibrary,
          ),
          title: CustomText(
            text: widget.subjectName,
            color: AppColors.gray900,
            size: 18,
            weight: FontWeight.bold,
          ),
          centerTitle: true,
        ),
        body: BrandBackdrop(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: switch (_phase) {
                _Phase.loading =>
                  const Center(child: CircularProgressIndicator()),
                _Phase.failed => _failed(),
                _Phase.question => _questionPage(),
                _Phase.done => _summary(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _failed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error500, size: 60),
          const Gap(16),
          const CustomText(
            text: 'فشل تحميل الأسئلة',
            color: AppColors.error600,
            size: 16,
            weight: FontWeight.bold,
          ),
          const Gap(8),
          CustomText(
            text: _error,
            color: AppColors.gray600,
            size: 13,
            align: TextAlign.center,
          ),
          const Gap(20),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- pages 1 & 2

  Widget _questionPage() {
    final item = _current;
    final position = _index + 1;
    final total = _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _progress(position, total),
        const Gap(20),
        Expanded(
          child: ListView(
            children: [
              // Type badge — the Arabic label, never the raw enum value.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary100),
                    ),
                    child: CustomText(
                      text: item.libraryable.typeLabel,
                      color: AppColors.brandPrimary,
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              _card(
                child: CustomText(
                  text: item.questionText.isEmpty
                      ? 'غير متوفر'
                      : item.questionText,
                  color: AppColors.gray900,
                  size: 18,
                  weight: FontWeight.w600,
                ),
              ),

              // Page 2 only. Not built at all on page 1 — there is nothing to
              // peek at, off-screen or otherwise.
              if (_answerShown) ...[
                const Gap(16),
                _card(
                  background: AppColors.success50,
                  border: AppColors.success500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AppColors.success600,
                          ),
                          const Gap(6),
                          const CustomText(
                            text: 'الإجابة',
                            color: AppColors.success700,
                            size: 13,
                            weight: FontWeight.bold,
                          ),
                        ],
                      ),
                      const Gap(8),
                      CustomText(
                        text: item.answerText.isEmpty
                            ? 'غير متوفرة'
                            : item.answerText,
                        color: AppColors.gray800,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(24),
            ],
          ),
        ),
        if (!_answerShown) _revealButton() else _answerActions(),
        const Gap(8),
      ],
    );
  }

  Widget _revealButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showAnswer,
        icon: const Icon(Icons.visibility_outlined, color: Colors.white),
        label: const Text(
          'إظهار الإجابة',
          style: TextStyle(
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
    );
  }

  /// Exactly two buttons on page 2, nothing else.
  Widget _answerActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _next,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text(
              'السؤال التالي',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
        ),
        const Gap(10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _remove,
            icon: const Icon(
              Icons.bookmark_remove_outlined,
              color: AppColors.error600,
            ),
            label: const Text(
              'إزالة السؤال من المكتبة',
              style: TextStyle(
                color: AppColors.error600,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progress(int position, int total) {
    final value = total == 0 ? 0.0 : position / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CustomText(
              text: 'السؤال $position من $total',
              color: AppColors.gray700,
              size: 14,
              weight: FontWeight.w600,
            ),
            const Spacer(),
            CustomText(
              text: '${(value * 100).round()}%',
              color: AppColors.brandPrimary,
              size: 13,
              weight: FontWeight.bold,
            ),
          ],
        ),
        const Gap(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: AppColors.gray200,
            color: AppColors.brandPrimary,
          ),
        ),
      ],
    );
  }

  Widget _card({
    required Widget child,
    Color? background,
    Color? border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ----------------------------------------------------------------- summary

  Widget _summary() {
    final remaining = _questions.length;
    final emptied = remaining == 0;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: emptied ? AppColors.primary50 : AppColors.success50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: emptied ? AppColors.primary100 : AppColors.success500,
                ),
              ),
              child: Icon(
                emptied ? Icons.inbox_outlined : Icons.check_circle_outline,
                size: 48,
                color: emptied ? AppColors.brandPrimary : AppColors.success600,
              ),
            ),
            const Gap(20),
            CustomText(
              text: emptied
                  ? 'لم يتبقَ شيء في هذه المادة'
                  : 'أنهيت أسئلة هذه المادة',
              color: AppColors.gray900,
              size: 20,
              weight: FontWeight.bold,
              align: TextAlign.center,
            ),
            const Gap(10),
            CustomText(
              text: emptied
                  ? 'تمت إزالة جميع الأسئلة المحفوظة، ولن تظهر هذه المادة في المكتبة.'
                  : 'يمكنك الدخول مرة أخرى في أي وقت لمراجعتها من جديد.',
              color: AppColors.gray700,
              size: 14,
              align: TextAlign.center,
            ),
            const Gap(24),
            Row(
              children: [
                Expanded(
                  child: _summaryTile(
                    value: _removedThisRun,
                    label: 'أُزيلت في هذه الجلسة',
                    color: AppColors.error600,
                    background: AppColors.error50,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _summaryTile(
                    value: remaining,
                    label: 'ما زالت في المكتبة',
                    color: AppColors.brandPrimary,
                    background: AppColors.primary50,
                  ),
                ),
              ],
            ),
            const Gap(28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _backToLibrary,
                icon: const Icon(Icons.library_books_outlined,
                    color: Colors.white),
                label: const Text(
                  'العودة إلى المكتبة',
                  style: TextStyle(
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
            if (!emptied) ...[
              const Gap(10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // Re-entry without leaving the screen. Counters reset, and
                  // nothing is re-added or re-recorded.
                  onPressed: _load,
                  icon: const Icon(Icons.refresh,
                      color: AppColors.brandPrimary),
                  label: const Text(
                    'مراجعتها من جديد',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.brandPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryTile({
    required int value,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
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
            size: 12,
            weight: FontWeight.w600,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
