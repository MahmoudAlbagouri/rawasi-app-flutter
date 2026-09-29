import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/views/profile_view.dart';
import 'package:rawasi_app_n/features/courses/views/courses_view.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/features/library/subjects_view.dart';
import 'package:rawasi_app_n/features/stats/views/statistics_view.dart';

/// The bottom navigation tabs, in display order.
///
/// Declaration order IS the tab order — in RTL the first entry sits rightmost.
/// Every screen names its tab (`NavTab.stats`) instead of hardcoding a
/// position, so reordering is one edit here rather than five files that have
/// to be kept in sync. Getting that wrong used to mean a tab highlighted one
/// screen while opening another, because the `items` list and the `onTap`
/// switch were maintained separately.
enum NavTab {
  home(icon: Icons.home_outlined, label: 'الرئيسية'),
  courses(icon: Icons.menu_book_outlined, label: 'المواد'),
  library(icon: Icons.library_books_outlined, label: 'المكتبة'),
  stats(icon: Icons.insights_outlined, label: 'إحصائياتي'),
  account(icon: Icons.person_outline, label: 'حسابي');

  const NavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  /// The screen this tab opens. Kept beside the label so a tab can never be
  /// labelled one thing and route somewhere else.
  Widget get screen => switch (this) {
        NavTab.home => const HomeView(),
        NavTab.courses => const CoursesView(),
        NavTab.library => const SubjectsView(),
        NavTab.stats => const StatisticsView(),
        NavTab.account => ProfileView(),
      };
}

class CustomBottomNavBar extends StatelessWidget {
  final NavTab current;

  const CustomBottomNavBar({super.key, this.current = NavTab.home});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200,
            spreadRadius: 4,
            blurRadius: 15,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: current.index,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.gray600,
        type: BottomNavigationBarType.fixed,
        // Five Arabic labels have to fit on a narrow phone without wrapping.
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) {
          final tab = NavTab.values[index];
          if (tab == current) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => tab.screen),
          );
        },
        items: [
          for (final tab in NavTab.values)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
