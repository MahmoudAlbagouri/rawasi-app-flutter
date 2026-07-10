import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/plan/day_plan_view.dart';
import 'package:rawasi_app_n/root.dart';

class SemesterPlanView extends StatelessWidget {
  final Map<String, dynamic> semester;

  const SemesterPlanView({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(semester['title']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // عنوان القسم
              Text(
                'الأيام',
                style: TextStyle(
                  color: AppColors.brandSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // قائمة الأيام
              Expanded(
                child: ListView.separated(
                  itemCount: 10,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final day = _getDayData(index);
                    return buildDayCard(context, day);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Map<String, dynamic> _getDayData(int index) {
    final days = [
      {'title': 'اليوم الأول', 'isLocked': false},
      {'title': 'اليوم الثاني', 'isLocked': false},
      {'title': 'اليوم الثالث', 'isLocked': false},
      {'title': 'اليوم الرابع', 'isLocked': false},
      {'title': 'اليوم الخامس', 'isLocked': false},
      {'title': 'اليوم السادس', 'isLocked': false},
      {'title': 'اليوم السابع', 'isLocked': false},
      {'title': 'اليوم الثامن', 'isLocked': false},
      {'title': 'اليوم التاسع', 'isLocked': false},
      {'title': 'اليوم العاشر', 'isLocked': false},
      {'title': 'اليوم الحادي عشر', 'isLocked': false}, // Added 11th day
    ];
    return days[index];
  }

  Widget buildDayCard(BuildContext context, Map<String, dynamic> day) {
    return GestureDetector(
      onTap: () {
        if (!day['isLocked']) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DayPlanView(day: day)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: day['isLocked'] ? AppColors.gray100 : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day['title'],
                    style: TextStyle(
                      color: AppColors.brandSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
