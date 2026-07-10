// lib/features/days/widgets/day_card_wrapper.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/days/data/day_lesson.dart';
import 'package:rawasi_app_n/shared/day_card.dart';

class DayCardWrapper extends StatelessWidget {
  final DayLesson lesson;
  final VoidCallback? onTap;

  const DayCardWrapper({super.key, required this.lesson, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.status == LessonStatus.completed;
    final isCurrent = lesson.status == LessonStatus.current;

    String subtitle = 'اليوم ${lesson.dayNumber}';
    if (lesson.isOverdueLesson) {
      subtitle += ' • ⚠️ متأخر';
    }

    final showStartButton = isCurrent && !isCompleted;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          // 🎨 بوب أب محسّن وجميل
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔒 أيقونة مقفول
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock,
                            color: AppColors.gray500,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // العنوان
                        Text(
                          'اليوم مقفول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // الرسالة
                        Text(
                          'هذا اليوم سيتم فتحه في الميعاد المحدد.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.gray600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // الزر
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'فهمت',
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
                  ),
                ),
              );
            },
          );
        }
      },
      child: DayCard(
        title: lesson.title,
        subtitle: subtitle,
        isCompleted: isCompleted,
        showStartButton: showStartButton,
        onPressed: onTap,
      ),
    );
  }
}
