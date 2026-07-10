// lib/features/library/views/content_types_view.dart

import 'package:flutter/material.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/features/library/questions_view.dart';
import 'package:rawasi_app_n/features/library/videos_view.dart';

class ContentTypesView extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final String initialType; // ← جديد: 'Question' أو 'Video'

  const ContentTypesView({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.initialType, // ← إلزامي الآن
  });

  @override
  State<ContentTypesView> createState() => _ContentTypesViewState();
}

class _ContentTypesViewState extends State<ContentTypesView> {
  late int _selectedContentType;

  @override
  void initState() {
    super.initState();
    // تحديد التبويب الافتراضي بناءً على initialType
    _selectedContentType = widget.initialType == 'Question' ? 0 : 1;
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
        title: Text(
          widget.subjectName,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              _buildTypeCard(
                icon: Icons.quiz,
                title: 'الأسئلة',
                isSelected: _selectedContentType == 0,
                onTap: () {
                  setState(() {
                    _selectedContentType = 0;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QuestionsView(subjectId: widget.subjectId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTypeCard(
                icon: Icons.play_circle,
                title: 'المحاضرات',
                isSelected: _selectedContentType == 1,
                onTap: () {
                  setState(() {
                    _selectedContentType = 1;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideosView(subjectId: widget.subjectId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withOpacity(0.1)
              : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(
                  isSelected ? 0.2 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.brandPrimary
                    : AppColors.brandSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.brandPrimary : AppColors.gray900,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? AppColors.brandPrimary : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
