import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/auth/views/profile_view.dart';
import 'package:rawasi_app_n/features/courses/views/courses_view.dart';
import 'package:rawasi_app_n/features/home/views/home_view.dart';
import 'package:rawasi_app_n/features/library/subjects_view.dart';
import 'package:rawasi_app_n/features/stats/views/statistics_view.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, this.selectedIndex = 0});

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
        currentIndex: selectedIndex,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.gray600,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (index) {
          if (index == selectedIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeView()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CoursesView()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SubjectsView()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileView()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StatisticsView()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'المواد',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            label: 'المكتبة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'حسابي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'إحصائياتي',
          ),
        ],
      ),
    );
  }
}
