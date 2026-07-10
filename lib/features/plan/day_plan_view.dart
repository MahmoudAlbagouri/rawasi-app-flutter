// day_plan_view.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/root.dart';

class DayPlanView extends StatelessWidget {
  final Map<String, dynamic> day;

  const DayPlanView({super.key, required this.day});

  // تحديد رقم اليوم من العنوان (مثلاً: "اليوم الأول" → 0)
  int _getDayIndex() {
    switch (day['title']) {
      case 'اليوم الأول':
        return 0;
      case 'اليوم الثاني':
        return 1;
      case 'اليوم الثالث':
        return 2;
      case 'اليوم الرابع':
        return 3;
      case 'اليوم الخامس':
        return 4;
      case 'اليوم السادس':
        return 5;
      case 'اليوم السابع':
        return 6;
      case 'اليوم الثامن':
        return 7;
      case 'اليوم التاسع':
        return 8;
      case 'اليوم العاشر':
        return 9;
      case 'اليوم الحادي عشر':
        return 10;
      default:
        return 0;
    }
  }

  // إرجاع بيانات المحتوى لكل يوم
  List<Map<String, String>> _getAllDayContents() {
    return [
      // اليوم 1
      {
        'fiqh': 'فيديو لشرح أول جزء في الفقه',
        'tafsir': 'فيديو لشرح أول جزء في التفسير',
        'reading': 'الورد القرآني',
      },
      // اليوم 2
      {
        'fiqh': 'فيديو لشرح أو حل أول جزء في الفقه',
        'tafsir': 'فيديو لشرح أو حل أول جزء في التفسير',
        'reading': 'الورد القرآني',
      },
      // اليوم 3
      {
        'fiqh': 'حل بنفسك الجزء الأول في الفقه',
        'tafsir': 'حل بنفسك الجزء الأول في التفسير',
        'reading': 'الورد القرآني',
      },
      // اليوم 4
      {
        'fiqh': 'حل بنفسك الجزء الأول في الفقه',
        'tafsir': 'حل بنفسك الجزء الأول في التفسير',
        'reading': 'الورد القرآني',
      },
      // اليوم 5
      {
        'fiqh': 'حل بنفسك الجزء الأول في الفقه',
        'tafsir': 'حل بنفسك الجزء الأول في التفسير',
        'reading': 'الورد القرآني',
      },
      // اليوم 6
      {
        'fiqh': 'فيديو لشرح ثاني جزء في الفقه',
        'tafsir': 'فيديو لشرح أول جزء في الحديث',
        'reading': 'الورد القرآني',
      },
      // اليوم 7
      {
        'fiqh': 'فيديو لشرح أو حل ثاني جزء في الفقه',
        'tafsir': 'فيديو لشرح أو حل أول جزء في الحديث',
        'reading': 'الورد القرآني',
      },
      // اليوم 8
      {
        'fiqh': 'حل بنفسك الجزء الثاني في الفقه',
        'tafsir': 'حل بنفسك الجزء الأول في الحديث',
        'reading': 'الورد القرآني',
      },
      // اليوم 9
      {
        'fiqh': 'حل بنفسك الجزء الثاني في الفقه',
        'tafsir': 'حل بنفسك الجزء الأول في الحديث',
        'reading': 'الورد القرآني',
      },
      // اليوم 10
      {
        'fiqh': 'حل بنفسك تراكمي في الفقه',
        'tafsir': 'حل بنفسك الجزء الأول في الحديث',
        'reading': 'الورد القرآني',
      },
      // اليوم 11 (أجازة)
      {
        'fiqh': 'لا توجد مهام',
        'tafsir': 'لا توجد مهام',
        'reading': 'يوم اجازة سعيد 🌸',
      },
    ];
  }

  Map<String, String> _getDayContent() {
    final contents = _getAllDayContents();
    final index = _getDayIndex();
    return contents[index];
  }

  @override
  Widget build(BuildContext context) {
    final content = _getDayContent();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(day['title']),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // كارت القراءة (القرآن)
                _buildLessonCard(
                  context,
                  title: 'القرآن الكريم',
                  content: content['reading']!,
                  progress: content['reading']!.contains('لا توجد') ? 0.0 : 1.0,
                  onContinue: () {
                    // يمكنك ربط هذا بفتح صفحة قراءة فعليّة لاحقًا
                  },
                ),
                const SizedBox(height: 24),

                // كارت التفسير (إذا كان غير فارغ)
                if (content['tafsir']!.isNotEmpty &&
                    !content['tafsir']!.contains('لا توجد'))
                  _buildLessonCard(
                    context,
                    title: 'تفسير',
                    content: content['tafsir']!,
                    progress: 0.6,
                    onContinue: () {
                      // منطق الانتقال للتفسير
                    },
                  )
                else if (content['tafsir']!.contains('لا توجد'))
                  _buildDisabledCard(
                    context,
                    title: 'تفسير',
                    content: content['tafsir']!,
                  ),

                if ((content['tafsir']!.isNotEmpty &&
                        !content['tafsir']!.contains('لا توجد')) ||
                    content['tafsir']!.contains('لا توجد'))
                  const SizedBox(height: 24),

                // كارت الفقه (إذا كان غير فارغ)
                if (content['fiqh']!.isNotEmpty &&
                    !content['fiqh']!.contains('لا توجد'))
                  _buildLessonCard(
                    context,
                    title: 'الفقه',
                    content: content['fiqh']!,
                    progress: 0.4,
                    onContinue: () {
                      // منطق الانتقال للفقه
                    },
                  )
                else if (content['fiqh']!.contains('لا توجد'))
                  _buildDisabledCard(
                    context,
                    title: 'الفقه',
                    content: content['fiqh']!,
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildLessonCard(
    BuildContext context, {
    required String title,
    required String content,
    required double progress,
    required void Function() onContinue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.brandSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.book, color: AppColors.brandPrimary, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledCard(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.block, color: AppColors.gray400, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: AppColors.gray500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
