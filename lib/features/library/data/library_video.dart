// lib/features/library/data/library_video.dart
import 'package:rawasi_app_n/features/library/data/content_item.dart';

class LibraryVideo {
  final String title;
  final String videoUrl;
  final String description;
  final int taskId;
  final int courseId;

  LibraryVideo({
    required this.title,
    required this.videoUrl,
    required this.description,
    required this.taskId,
    required this.courseId,
  });

  factory LibraryVideo.fromContentItem(ContentItem item) {
    final detail = item.libraryable;
    return LibraryVideo(
      title: detail.title ?? 'بدون عنوان',
      videoUrl: detail.video?.trim() ?? '',
      description: detail.description ?? 'لا يوجد وصف',
      taskId: detail.id,
      courseId: item.id, // أو أي قيمة مناسبة حسب الحاجة
    );
  }
}
