// lib/features/stats/views/statistics_view.dart
//
// Student statistics: overall completion, per-subject progress, study streak,
// time spent, weekly pace and the top-10 leaderboard.
//
// Every denominator comes from the backend's curriculum config, so a subject
// with nothing uploaded yet still shows its final total (e.g. 0/50) instead of
// a misleading 100%.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/home/widgets/trial_card.dart';
import 'package:rawasi_app_n/features/stats/widgets/my_rank_card.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/arabic_plural.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/study_reminder_card.dart';
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/stats/data/stats_repo.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

/// What the screen can show, resolved before /analytics is ever called.
class _StatsPage {
  /// Non-null when the student cannot see statistics at all.
  final GateReason? gate;
  final StudentStats? stats;

  const _StatsPage({this.gate, this.stats});
}

class _StatisticsViewState extends State<StatisticsView> {
  late Future<_StatsPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Checks auth and activation FIRST.
  ///
  /// /analytics sits behind auth:student + student.active, so for a signed-out
  /// or unactivated student the call is guaranteed to fail. Firing it anyway
  /// produced a raw API message under an "إعادة المحاولة" button that could
  /// never succeed — retrying does not log anybody in. The same two states are
  /// already modelled by AccountGate, which courses_view uses.
  Future<_StatsPage> _load() async {
    if (!await isUserSignedIn()) {
      return const _StatsPage(gate: GateReason.signedOut);
    }

    Student? profile;
    try {
      profile = await ProfileRepository().fetchProfile();
    } catch (_) {
      // Profile itself failed: fall through and let the stats call decide, so
      // a transient network error still gets the retry button.
      profile = null;
    }

    if (profile != null) {
      final reason = gateFor(profile);
      if (reason != null) return _StatsPage(gate: reason);
    }

    return _StatsPage(stats: await StatsRepo().fetchStats());
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Same treatment as home / courses / library: a white base under the
      // shared BrandBackdrop, rather than a flat gray50.
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Reachable both as a bottom-nav tab and pushed from the profile menu:
        // only offer back when there is something to go back to.
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: false,
        title: const Text(
          'إحصائياتي',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BrandBackdrop(
        child: SafeArea(
        child: FutureBuilder<_StatsPage>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // _error keeps its retry button for genuine network/server
            // failures, where retrying actually helps.
            if (snapshot.hasError) {
              return _error(snapshot.error);
            }

            final page = snapshot.data!;

            if (page.gate != null) {
              return AccountGate(
                reason: page.gate!,
                action: page.gate == GateReason.signedOut
                    ? const AuthActions()
                    : null,
              );
            }

            final stats = page.stats!;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _overallCard(stats.completion),
                  const Gap(16),
                  _row(stats),
                  const Gap(16),
                  _pacingCard(stats.pacing),
                  const Gap(16),
                  TrialCard(trial: stats.trial),
                  const Gap(16),
                  StudyReminderCard(inactivity: stats.inactivity),
                  const Gap(20),
                  _sectionTitle('تقدم المواد'),
                  const Gap(12),
                  _subjectsGrid(stats.subjects),
                  const Gap(20),
                  _sectionTitle('لوحة المتصدرين'),
                  const Gap(4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomText(
                      text: 'أول عشرة في ${stats.leaderboard.scopeLabel}',
                      color: AppColors.gray600,
                      size: 13,
                    ),
                  ),
                  const Gap(12),
                  MyRankCard(board: stats.leaderboard),
                  const Gap(12),
                  _leaderboardCard(stats.leaderboard, myCompletedLessons: stats.completion.completedLessons),
                  const Gap(24),
                ],
              ),
            );
          },
        ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(current: NavTab.stats),
    );
  }

  Widget _error(Object? error) {
    final message = error is ApiError ? error.message : 'فشل تحميل الإحصائيات';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: AppColors.gray400),
            const Gap(16),
            CustomText(
              text: message,
              color: AppColors.gray700,
              size: 15,
              align: TextAlign.center,
            ),
            const Gap(20),
            ElevatedButton(
              onPressed: _reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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

  Widget _sectionTitle(String text) => Align(
        alignment: Alignment.centerRight,
        child: CustomText(
          text: text,
          color: AppColors.brandPrimary,
          size: 17,
          weight: FontWeight.bold,
        ),
      );

  // ---------------------------------------------------------------------------
  // 1. Overall completion
  // ---------------------------------------------------------------------------

  Widget _overallCard(Completion c) {
    final fraction = c.fraction;

    return _card(
      child: Column(
        children: [
          CustomText(
            text: 'المكتمل',
            color: AppColors.gray900,
            size: 16,
            weight: FontWeight.bold,
          ),
          const Gap(16),
          SizedBox(
            height: 132,
            width: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 132,
                  width: 132,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 11,
                    backgroundColor: AppColors.gray200,
                    color: AppColors.brandPrimary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      // Shared formatter — home prints the identical string.
                      text: '${c.percentLabel}%',
                      color: AppColors.brandPrimary,
                      size: 28,
                      weight: FontWeight.bold,
                    ),
                    CustomText(
                      text: 'من المنهج',
                      color: AppColors.gray600,
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(16),
          CustomText(
            text: '${c.completedLessons} من ${c.totalLessons} درسًا',
            color: AppColors.gray800,
            size: 15,
            weight: FontWeight.w600,
          ),
          const Gap(4),
          CustomText(
            text: 'المتبقي: ${c.remainingLessons} درسًا',
            color: AppColors.gray600,
            size: 13,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3 + 4. Streak and study time
  // ---------------------------------------------------------------------------

  Widget _row(StudentStats stats) {
    // This Row sits directly inside the ListView, which offers unbounded
    // height. `stretch` alone therefore asked each tile to be infinitely
    // tall ("BoxConstraints forces an infinite height"), and that failed
    // layout took down every card after this one. IntrinsicHeight bounds
    // the Row to its tallest tile; stretch then makes the two tiles match.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _card(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department,
                      color: AppColors.warning500, size: 30),
                  const Gap(8),
                  CustomText(
                    text: 'الأيام المتتالية',
                    color: AppColors.gray600,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                  const Gap(8),
                  CustomText(
                    text: '${stats.streak.current}',
                    color: AppColors.gray900,
                    size: 26,
                    weight: FontWeight.bold,
                  ),
                  CustomText(
                    text: 'يوم حالياً',
                    color: AppColors.gray600,
                    size: 12,
                  ),
                  const Gap(6),
                  CustomText(
                    text: 'الأطول: ${stats.streak.longest} يوم',
                    color: AppColors.success700,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: _card(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Column(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.brandPrimary, size: 30),
                  const Gap(8),
                  CustomText(
                    text: 'مدة مذاكرتك',
                    color: AppColors.gray600,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                  const Gap(8),
                  CustomText(
                    text: stats.timeSpent.label,
                    color: AppColors.gray900,
                    size: 17,
                    weight: FontWeight.bold,
                    align: TextAlign.center,
                  ),
                  const Gap(6),
                  CustomText(
                    text: '${stats.timeSpent.minutes} دقيقة إجمالاً',
                    color: AppColors.gray600,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Weekly pace
  // ---------------------------------------------------------------------------

  Widget _pacingCard(Pacing p) {
    // A student who has completed nothing has no pace to report. Printing
    // "بمعدل 0 درس في الأسبوع" next to a blank projection reads like a broken
    // card rather than an empty one.
    if (!p.hasStarted || p.completedLessons <= 0) {
      return _card(
        child: Row(
          children: [
            Icon(Icons.speed, color: AppColors.gray400, size: 30),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'الدروس المكتملة أسبوعياً',
                    color: AppColors.gray900,
                    size: 15,
                    weight: FontWeight.bold,
                  ),
                  const Gap(6),
                  CustomText(
                    text: 'لم تبدأ بعد',
                    color: AppColors.gray700,
                    size: 13,
                  ),
                  const Gap(2),
                  CustomText(
                    text: 'أكمل أول درس ليظهر معدلك الأسبوعي',
                    color: AppColors.gray600,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final projected = arabicDate(p.estimatedCompletionDate);

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.speed, color: AppColors.brandPrimary, size: 30),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomText(
                        text: 'الدروس المكتملة أسبوعياً',
                        color: AppColors.gray900,
                        size: 15,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    _ratioChip(p),
                  ],
                ),
                const Gap(6),
                CustomText(
                  // The ratio above and this average are the same division, so
                  // they can never contradict each other.
                  text:
                      '${arabicLessons(p.completedLessons)} في ${arabicWeeks(p.weeksElapsed)}'
                      ' — بمعدل ${_trim(p.lessonsPerWeek)} ${arabicLessonWord(p.lessonsPerWeek)} في الأسبوع',
                  color: AppColors.gray700,
                  size: 13,
                ),
                const Gap(2),
                CustomText(
                  text: 'المتبقي: ${arabicLessons(p.remainingLessons)}',
                  color: AppColors.gray600,
                  size: 13,
                ),
                if (projected != null) ...[
                  const Gap(6),
                  CustomText(
                    text: 'بهذا المعدل تنتهي في $projected',
                    color: AppColors.success700,
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The "6 / 2" figure: lessons completed over weeks studying.
  ///
  /// Forced LTR. In an Arabic paragraph the bidi algorithm reads the slash and
  /// the surrounding spaces as neutral and resolves them to the base direction,
  /// which lays the two numbers out swapped — "6 / 2" displayed as "2 / 6".
  Widget _ratioChip(Pacing p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CustomText(
          text: p.ratioLabel,
          color: AppColors.brandPrimary,
          size: 17,
          weight: FontWeight.bold,
        ),
      ),
    );
  }

  /// The counted noun for a fractional rate: 0.5 درس, 2 درسان, 7 دروس.
  String arabicLessonWord(double rate) {
    if (rate <= 1) return 'درس';
    if (rate < 3) return 'درس';
    return 'دروس';
  }

  // ---------------------------------------------------------------------------
  // Days since the last new lesson
  // ---------------------------------------------------------------------------

  // The reminder itself lives in StudyReminderCard, shared with home so the
  // two cannot drift. It is driven by delay_days alone and knows nothing
  // about lesson unlocking.

  // ---------------------------------------------------------------------------
  // 2. Per-subject progress
  // ---------------------------------------------------------------------------

  /// One column on phones, two side by side once there is room.
  Widget _subjectsGrid(List<SubjectProgress> subjects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        const spacing = 12.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final s in subjects)
              SizedBox(width: width, child: _subjectCard(s)),
          ],
        );
      },
    );
  }

  /// A course card in the style of the reference: a banner carrying the subject
  /// name, then the name again with its lesson count, and a labelled progress
  /// bar. Totals are the curriculum figures, so a subject with little uploaded
  /// content still shows its true denominator.
  Widget _subjectCard(SubjectProgress s) {
    final fraction = (s.percentage / 100).clamp(0.0, 1.0);
    final accent = _subjectAccent(s.key);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner — stands in for the course image.
          Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accent.withOpacity(0.18), accent.withOpacity(0.04)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -18,
                  left: -18,
                  child: Icon(_subjectIcon(s.key), size: 96, color: accent.withOpacity(0.12)),
                ),
                Center(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      color: accent,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: s.label,
                  color: AppColors.gray900,
                  size: 16,
                  weight: FontWeight.bold,
                ),
                const Gap(8),
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 16, color: AppColors.gray500),
                    const Gap(4),
                    CustomText(
                      text: '${s.totalLessons} ${s.unitLabel}',
                      color: AppColors.gray600,
                      size: 12,
                    ),
                    const Gap(14),
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.gray500),
                    const Gap(4),
                    CustomText(
                      text: 'أكملت ${s.completedLessons}',
                      color: AppColors.gray600,
                      size: 12,
                    ),
                    if (s.availableLessons < s.totalLessons) ...[
                      const Spacer(),
                      // Content is still being uploaded; say what is reachable
                      // today instead of implying the rest is missing.
                      CustomText(
                        text: 'المتاح ${s.availableLessons}',
                        color: AppColors.gray400,
                        size: 11,
                      ),
                    ],
                  ],
                ),
                const Gap(14),
                Row(
                  children: [
                    CustomText(
                      text: 'التقدم',
                      color: AppColors.gray700,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                    const Spacer(),
                    CustomText(
                      text: '${_trim(s.percentage)}%',
                      color: AppColors.gray900,
                      size: 13,
                      weight: FontWeight.bold,
                    ),
                  ],
                ),
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    backgroundColor: AppColors.gray200,
                    color: accent,
                  ),
                ),
                const Gap(6),
                CustomText(
                  text: '${s.completedLessons} من ${s.totalLessons} ${s.unitLabel}',
                  color: AppColors.gray500,
                  size: 11,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _subjectIcon(String key) => switch (key) {
        'quran' => Icons.auto_stories,
        'fiqh_hanafi' || 'fiqh_shafii' => Icons.balance,
        'tafseer' => Icons.manage_search,
        'hadith' => Icons.format_quote,
        'tawheed' => Icons.star,
        'inheritance' => Icons.account_tree,
        _ => Icons.menu_book,
      };

  Color _subjectAccent(String key) => switch (key) {
        'quran' => const Color(0xFF2E7D32),
        'fiqh_hanafi' || 'fiqh_shafii' => const Color(0xFF6D4C41),
        'tafseer' => const Color(0xFF8D5A3B),
        'hadith' => const Color(0xFF1565C0),
        'tawheed' => const Color(0xFF6A1B9A),
        'inheritance' => const Color(0xFF00695C),
        _ => AppColors.brandPrimary,
      };

  // ---------------------------------------------------------------------------
  // 6. Leaderboard
  // ---------------------------------------------------------------------------

  Widget _leaderboardCard(Leaderboard board, {required int myCompletedLessons}) {
    if (board.top.isEmpty) {
      return _card(
        child: CustomText(
          text: 'لا توجد نتائج بعد — كن أول المتصدرين!',
          color: AppColors.gray600,
          size: 14,
          align: TextAlign.center,
        ),
      );
    }

    return _card(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        children: [
          // The student's own standing now has a dedicated card ABOVE this
          // list (_myRankCard), shown always — including when they are inside
          // the top ten, which is the motivating case the old conditional
          // append suppressed. The in-list highlight stays.
          ...board.top.map(_leaderboardRow),
        ],
      ),
    );
  }

  Widget _leaderboardRow(LeaderboardEntry e) {
    final medal = switch (e.rank) {
      1 => const Color(0xFFD4AF37),
      2 => const Color(0xFF9CA3AF),
      3 => const Color(0xFFB87333),
      _ => AppColors.gray300,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: e.isCurrentStudent ? AppColors.primary50 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: e.isCurrentStudent
            ? Border.all(color: AppColors.brandPrimary.withOpacity(0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              // Green for every place, as in the reference; first place is
              // distinguished by the trophy below rather than by tint, so the
              // numbers stay legible at small sizes.
              color: AppColors.success600,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${e.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: e.name,
                  color: AppColors.gray900,
                  size: 14,
                  weight: e.isCurrentStudent ? FontWeight.bold : FontWeight.w500,
                  // Names range from "Hamedo Mekky" to
                  // "مروان أحمد إبراهيم الطناني". Wrapping at two lines keeps
                  // the row height bounded without truncating most names.
                  maxLines: 2,
                ),
                CustomText(
                  text: '${arabicLessons(e.completedLessons)} مكتمل',
                  color: AppColors.gray500,
                  size: 11,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const Gap(8),

          // Trophy on first place only. The medal colour already varies by
          // rank; this reuses it rather than introducing a second scheme.
          if (e.rank == 1) ...[
            Icon(Icons.emoji_events, color: medal, size: 20),
            const Gap(6),
          ],

          // Fixed width so the points column does not shift as names wrap.
          SizedBox(
            width: 62,
            child: CustomText(
              // Arabic counted noun: نقطة / نقطتان / نقاط, not نقطة for every
              // number. `completed_lessons` above is a caption - points are the
              // ranking key.
              text: arabicPoints(e.points),
              color: AppColors.brandPrimary,
              size: 13,
              weight: FontWeight.w600,
              align: TextAlign.end,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// 40.0 → "40", 2.55 → "2.55" — avoids a trailing ".0" on whole numbers.
  String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}
