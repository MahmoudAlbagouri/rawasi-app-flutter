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
import 'package:rawasi_app_n/shared/arabic_plural.dart';
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

class _StatisticsViewState extends State<StatisticsView> {
  late Future<StudentStats> _future;

  @override
  void initState() {
    super.initState();
    _future = StatsRepo().fetchStats();
  }

  void _reload() {
    setState(() => _future = StatsRepo().fetchStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
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
      body: SafeArea(
        child: FutureBuilder<StudentStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _error(snapshot.error);
            }

            final stats = snapshot.data!;
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
                  _inactivityCard(stats.inactivity),
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
                  _leaderboardCard(stats.leaderboard, myCompletedLessons: stats.completion.completedLessons),
                  const Gap(24),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 4),
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
    return Row(
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
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Weekly pace
  // ---------------------------------------------------------------------------

  Widget _pacingCard(Pacing p) {
    // A student who has completed nothing has no pace to report. Printing
    // "بمعدل 0 درس في الأسبوع" next to a blank projection reads like a broken
    // card rather than an empty one.
    if (p.lessonsPerWeek <= 0) {
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

    // Everything finished in the first day or two makes the weekly rate
    // mathematically true but useless — one day is a seventh of a week, so a
    // single lesson reads as "7 دروس في الأسبوع". The backend keeps the raw
    // figure on purpose; the honest thing here is to caption it rather than
    // quietly rewrite the number or project a finish date off it.
    final isEarly = p.lessonsPerWeek > p.completedLessons && p.completedLessons > 0;

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
                CustomText(
                  text: 'الدروس المكتملة أسبوعياً',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                const Gap(6),
                CustomText(
                  text: 'بمعدل ${_trim(p.lessonsPerWeek)} ${arabicLessonWord(p.lessonsPerWeek)} في الأسبوع',
                  color: AppColors.gray700,
                  size: 13,
                ),
                const Gap(2),
                CustomText(
                  text: 'المتبقي: ${arabicLessons(p.remainingLessons)}',
                  color: AppColors.gray600,
                  size: 13,
                ),
                if (isEarly) ...[
                  const Gap(6),
                  CustomText(
                    text: 'معدل مبدئي — سيستقر بعد أسبوع من المذاكرة',
                    color: AppColors.warning700,
                    size: 12,
                  ),
                ] else if (projected != null) ...[
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

  /// The counted noun for a fractional rate: 0.5 درس, 2 درسان, 7 دروس.
  String arabicLessonWord(double rate) {
    if (rate <= 1) return 'درس';
    if (rate < 3) return 'درس';
    return 'دروس';
  }

  // ---------------------------------------------------------------------------
  // Days since the last new lesson
  // ---------------------------------------------------------------------------

  Widget _inactivityCard(Inactivity a) {
    final days = a.delayDays;

    final (Color accent, IconData icon) = switch (days) {
      null => (AppColors.gray500, Icons.hourglass_empty),
      0 => (AppColors.success600, Icons.check_circle_outline),
      _ when days < 3 => (AppColors.brandPrimary, Icons.schedule),
      _ => (AppColors.warning700, Icons.lock_open_outlined),
    };

    return _card(
      child: Row(
        children: [
          Icon(icon, color: accent, size: 30),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'أيام الانقطاع عن الدروس الجديدة',
                  color: AppColors.gray900,
                  size: 15,
                  weight: FontWeight.bold,
                ),
                const Gap(6),
                CustomText(
                  text: a.label,
                  color: accent,
                  size: 14,
                  weight: FontWeight.w600,
                ),
                const Gap(2),
                CustomText(
                  text: a.hint,
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
          ...board.top.map(_leaderboardRow),
          if (board.myRank != null && !board.top.any((e) => e.isCurrentStudent)) ...[
            const Divider(height: 16),
            _leaderboardRow(
              LeaderboardEntry(
                rank: board.myRank!,
                name: 'ترتيبك',
                points: board.myPoints,
                completedLessons: myCompletedLessons,
                isCurrentStudent: true,
              ),
            ),
          ],
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
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
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
                ),
                CustomText(
                  text: '${arabicLessons(e.completedLessons)} مكتمل',
                  color: AppColors.gray500,
                  size: 11,
                ),
              ],
            ),
          ),
          CustomText(
            // Arabic counted noun: نقطة / نقطتان / نقاط, not نقطة for every
            // number. `completed_lessons` above is a caption - points are the
            // ranking key.
            text: arabicPoints(e.points),
            color: AppColors.brandPrimary,
            size: 13,
            weight: FontWeight.w600,
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
