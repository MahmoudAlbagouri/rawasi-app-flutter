import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:gap/gap.dart';

class QuestionsView extends StatefulWidget {
  final int subjectId;

  const QuestionsView({super.key, required this.subjectId});

  @override
  State<QuestionsView> createState() => _QuestionsViewState();
}

class _QuestionsViewState extends State<QuestionsView> {
  late Future<List<ContentItem>> _questionsFuture;
  List<ContentItem> _currentQuestions = [];
  final LibraryRepo _repo = LibraryRepo();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _questionsFuture = _repo.fetchContent(widget.subjectId, 'Question');
  }

  // ✅ دالة عرض بوب أب السؤال
  void _showQuestionDialog(ContentDetail question) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة السؤال
                Icon(
                  Icons.quiz_outlined,
                  color: AppColors.brandPrimary,
                  size: 32,
                ),
                const SizedBox(height: 16),
                // العنوان
                Text(
                  'السؤال',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                // نص السؤال
                Text(
                  question.question ?? 'غير متوفر',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.gray800,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                // الإجابة الصحيحة
                Text(
                  'الإجابة الصحيحة:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  question.correctAnswer ?? 'غير متوفرة',
                  style: TextStyle(fontSize: 15, color: AppColors.gray700),
                ),
                const SizedBox(height: 24),
                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'إغلاق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ دالة محسّنة للحذف مع UX أفضل
  Future<void> _removeFromLibrary(ContentItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا السؤال من مكتبتك؟'),
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

    final originalList = List<ContentItem>.from(_currentQuestions);

    setState(() {
      _currentQuestions.removeWhere((q) => q.id == item.id);
    });

    try {
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
      setState(() {
        _currentQuestions = originalList;
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
          'الأسئلة',
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
          future: _questionsFuture,
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
                      'فشل تحميل الأسئلة',
                      style: TextStyle(color: AppColors.error600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.done) {
              _currentQuestions = snapshot.data ?? [];
            }

            if (_currentQuestions.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد أسئلة متاحة',
                  style: TextStyle(color: AppColors.gray600),
                ),
              );
            }

            return ListView.builder(
              itemCount: _currentQuestions.length,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              itemBuilder: (context, index) {
                final item = _currentQuestions[index];
                final q = item.libraryable;

                // 👇 جعل السؤال كله قابلاً للنقر
                return GestureDetector(
                  onTap: () => _showQuestionDialog(q),
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
                                Icons.quiz,
                                color: AppColors.brandPrimary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q.question ?? 'سؤال غير معروف',
                                style: const TextStyle(
                                  color: AppColors.brandSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الإجابة الصحيحة: ${q.correctAnswer ?? 'غير متوفرة'}',
                          style: TextStyle(
                            color: AppColors.gray600,
                            fontSize: 14,
                          ),
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
