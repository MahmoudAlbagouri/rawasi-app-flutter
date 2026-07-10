// lib/features/lessons/views/lessons_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/exam/views/exam_loading_screen.dart';
import 'package:rawasi_app_n/features/lessons/data/lessons_item.dart';
import 'package:rawasi_app_n/features/lessons/data/lessons_repo.dart';
import 'package:rawasi_app_n/features/lesson/views/lesson_video_view.dart';
import 'package:rawasi_app_n/features/lessons/widgets/lesson_card.dart';
import 'package:rawasi_app_n/root.dart';

class LessonsView extends StatefulWidget {
  final int dayId;
  final String dayTitle;

  const LessonsView({super.key, required this.dayId, required this.dayTitle});

  @override
  State<LessonsView> createState() => _LessonsViewState();
}

class _LessonsViewState extends State<LessonsView> {
  late Future<List<LessonItem>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = LessonsRepo().fetchLessonsByDay(widget.dayId);
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

        title: Text(
          widget.dayTitle,
          style: const TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: FutureBuilder<List<LessonItem>>(
            future: _lessonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        color: AppColors.gray400,
                        size: 48,
                      ),
                      Gap(12),
                      Text(
                        'تعذر تحميل الدروس',
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(6),
                      Text(
                        'يرجى المحاولة لاحقًا',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ],
                  ),
                );
              }

              final lessons = snapshot.data ?? [];
              if (lessons.isEmpty) {
                return const Center(child: Text('لا توجد دروس لهذا اليوم'));
              }

              return ListView.separated(
                itemCount: lessons.length,
                separatorBuilder: (context, index) => Gap(12),
                itemBuilder: (context, index) {
                  final lessonItem = lessons[index];
                  return LessonCard(
                    title: lessonItem.title,
                    content: lessonItem.type == 'Question'
                        ? 'أسئلة تفاعلية'
                        : 'فيديو تعليمي',
                    isVideo: lessonItem.type == 'Video',
                    onContinue: () {
                      if (lessonItem.type == 'Question') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamLoadingScreen(
                              dayId: widget.dayId,
                              courseId: lessonItem.id,
                            ),
                          ),
                        );
                      } else if (lessonItem.type == 'Video') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonVideoView(
                              dayId: widget.dayId,
                              courseId: lessonItem.id,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }
}
