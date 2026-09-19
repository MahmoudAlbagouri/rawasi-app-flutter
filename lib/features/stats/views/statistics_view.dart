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
import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/features/stats/data/stats_repo.dart';
import 'package:rawasi_app_n/features/stats/data/student_stats.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
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
                  const Gap(20),
                  _sectionTitle('المواد'),
                  const Gap(12),
                  ...stats.subjects.map(_subjectCard),
                  const Gap(20),
                  _sectionTitle('أول عشرة'),
                  const Gap(12),
                  _leaderboardCard(stats.leaderboard),
                  const Gap(24),
                ],
              ),
            );
          },
        ),
      ),
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
    final fraction = (c.percentage / 100).clamp(0.0, 1.0);

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
                      text: '${_trim(c.percentage)}%',
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
    return _card(
      child: Row(
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
                  text: 'بمعدل ${_trim(p.lessonsPerWeek)} درس في الأسبوع',
                  color: AppColors.gray700,
                  size: 13,
                ),
                const Gap(2),
                CustomText(
                  text: 'المتبقي: ${p.remainingLessons} درسًا',
                  color: AppColors.gray600,
                  size: 13,
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

  Widget _subjectCard(SubjectProgress s) {
    final fraction = (s.percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: s.label,
                    color: AppColors.gray900,
                    size: 15,
                    weight: FontWeight.w600,
                  ),
                ),
                CustomText(
                  text: '${_trim(s.percentage)}%',
                  color: AppColors.brandPrimary,
                  size: 14,
                  weight: FontWeight.bold,
                ),
              ],
            ),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: AppColors.gray200,
                color: AppColors.brandPrimary,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                CustomText(
                  text:
                      '${s.completedLessons} من ${s.totalLessons} ${s.unitLabel}',
                  color: AppColors.gray700,
                  size: 12,
                ),
                const Spacer(),
                // Content is still being uploaded, so say how much a student can
                // actually reach today rather than implying the rest is missing.
                if (s.availableLessons < s.totalLessons)
                  CustomText(
                    text: 'المتاح الآن: ${s.availableLessons}',
                    color: AppColors.gray500,
                    size: 12,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Leaderboard
  // ---------------------------------------------------------------------------

  Widget _leaderboardCard(Leaderboard board) {
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
            child: CustomText(
              text: e.name,
              color: AppColors.gray900,
              size: 14,
              weight: e.isCurrentStudent ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          CustomText(
            text: '${e.points} نقطة',
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
