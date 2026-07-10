// lib/features/library/views/videos_view.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/features/library/data/library_video.dart';
import 'package:rawasi_app_n/features/library/library_video_view.dart';

class VideosView extends StatefulWidget {
  final int subjectId;

  const VideosView({super.key, required this.subjectId});

  @override
  State<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<VideosView> {
  late Future<List<ContentItem>> _videosFuture;
  List<ContentItem> _currentVideos = []; // ← لتخزين القائمة الحالية
  final LibraryRepo _repo = LibraryRepo();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _videosFuture = _repo.fetchContent(widget.subjectId, 'Video');
  }

  // ✅ دالة محسّنة للحذف مع UX أفضل
  Future<void> _removeFromLibrary(ContentItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الفيديو من مكتبتك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 👇 1. احفظ نسخة من القائمة الحالية
    final originalList = List<ContentItem>.from(_currentVideos);

    // 👇 2. احذف العنصر فورًا من الواجهة
    setState(() {
      _currentVideos.removeWhere((v) => v.id == item.id);
    });

    try {
      // 👇 3. أرسل طلب الحذف إلى السيرفر
      final success = await _repo.removeFromLibrary(
        contentId: item.id,
        courseId: widget.subjectId,
        taskId: item.libraryable.id,
        type: item.type.toLowerCase(),
      );

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
      } else {
        throw Exception('فشل الحذف: لم يتم التأكيد من السيرفر');
      }
    } catch (e) {
      // 👇 4. في حالة الفشل، أعد العنصر
      setState(() {
        _currentVideos = originalList;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray800),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'المحاضرات',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<ContentItem>>(
          future: _videosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: AppColors.error500, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'فشل تحميل المحاضرات',
                      style: TextStyle(color: AppColors.error600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // 👇 تحديث القائمة الداخلية
            if (snapshot.connectionState == ConnectionState.done) {
              _currentVideos = snapshot.data ?? [];
            }

            if (_currentVideos.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد محاضرات متاحة',
                  style: TextStyle(color: AppColors.gray600),
                ),
              );
            }

            // 👇 استخدام _currentVideos
            return ListView.builder(
              itemCount: _currentVideos.length,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              itemBuilder: (context, index) {
                final item = _currentVideos[index];
                final v = item.libraryable;
                return GestureDetector(
                  onTap: () {
                    if (v.video != null && v.video!.isNotEmpty) {
                      final libraryVideo = LibraryVideo.fromContentItem(item);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LibraryVideoView(video: libraryVideo),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gray200.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_circle,
                                color: AppColors.brandPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.title ?? 'محاضرة غير معروفة',
                                    style: const TextStyle(
                                      color: AppColors.brandSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (v.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      v.description!,
                                      style: TextStyle(
                                        color: AppColors.gray600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.gray400,
                              size: 18,
                            ),
                          ],
                        ),
                        const Gap(12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _removeFromLibrary(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'إزالة من المكتبة',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
