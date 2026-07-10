// lib/features/library/views/library_views.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/content_types_view.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/root.dart';

class LibraryViews extends StatefulWidget {
  const LibraryViews({super.key});

  @override
  State<LibraryViews> createState() => _LibraryViewsState();
}

class _LibraryViewsState extends State<LibraryViews> {
  String searchQuery = '';
  int selectedTab = 0; // 0 = أسئلة, 1 = محاضرات (فيديو)

  late Future<List<SubjectItem>> _futureData;
  final LibraryRepo _libraryRepo = LibraryRepo();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureData = _libraryRepo.fetchSubjects();
    });
  }

  List<SubjectItem> _filterSubjects(List<SubjectItem> subjects) {
    if (searchQuery.isEmpty) return subjects;
    return subjects.where((subject) {
      return subject.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'المكتبة',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شريط البحث
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray200.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.gray500, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'بحث في المكتبة...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppColors.gray400),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // زرَي التبويبات
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedTab != 1
                          ? () {
                              setState(() {
                                selectedTab = 1;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedTab == 1
                            ? AppColors.brandPrimary
                            : AppColors.white,
                        foregroundColor: selectedTab == 1
                            ? Colors.white
                            : AppColors.brandSecondary,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: selectedTab == 1
                                ? AppColors.brandPrimary
                                : AppColors.gray300,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'محاضرات',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedTab != 0
                          ? () {
                              setState(() {
                                selectedTab = 0;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedTab == 0
                            ? AppColors.brandPrimary
                            : AppColors.white,
                        foregroundColor: selectedTab == 0
                            ? Colors.white
                            : AppColors.brandSecondary,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: selectedTab == 0
                                ? AppColors.brandPrimary
                                : AppColors.gray300,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'الأسئلة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // عرض المحتوى (مع معالجة الحالات: loading, error, empty, success)
              Expanded(
                child: FutureBuilder<List<SubjectItem>>(
                  future: _futureData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingScreen();
                    } else if (snapshot.hasError) {
                      return _ErrorScreen(
                        title: 'فشل تحميل المواد',
                        message: snapshot.error.toString(),
                        onRetry: _loadData,
                      );
                    } else {
                      final allSubjects = snapshot.data!;
                      final filteredSubjects = _filterSubjects(allSubjects);

                      if (filteredSubjects.isEmpty) {
                        if (searchQuery.isEmpty) {
                          return _EmptyScreen(
                            title: 'لا توجد مواد بعد',
                            message:
                                'ستظهر المواد هنا بمجرد إضافة محتوى من الإدارة.',
                          );
                        } else {
                          return _EmptyScreen(
                            title: 'لا توجد نتائج',
                            message: 'لم نجد مواد مطابقة لـ "$searchQuery"',
                          );
                        }
                      }

                      return ListView.separated(
                        itemCount: filteredSubjects.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final subject = filteredSubjects[index];
                          return _buildSubjectCard(subject);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildSubjectCard(SubjectItem subject) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContentTypesView(
              subjectId: subject.id,
              subjectName: subject.name,
              initialType: selectedTab == 0 ? 'Question' : 'Video',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedTab == 0 ? Icons.quiz : Icons.play_circle,
                color: AppColors.brandPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subject.name,
                style: TextStyle(
                  color: AppColors.brandSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.gray400, size: 18),
          ],
        ),
      ),
    );
  }
}

// === شاشة التحميل ===
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.brandPrimary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المكتبة...',
            style: TextStyle(color: AppColors.gray600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// === شاشة الخطأ (مُحسّنة حسب تصميمك في الصورة) ===
class _ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الأيقونة الحمراء الكبيرة
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error500,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          // العنوان
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // الرسالة التفصيلية (بخط أصغر)
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          // زر إعادة المحاولة
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === شاشة الفراغ (لا مواد / لا نتائج) ===
class _EmptyScreen extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyScreen({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.library_books_outlined,
              color: AppColors.gray400,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray900,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.gray600, fontSize: 14),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
