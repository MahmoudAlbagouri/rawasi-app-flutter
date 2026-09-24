// lib/features/library/views/subjects_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/core/utils/auth_helper.dart';
import 'package:rawasi_app_n/features/library/data/content_item.dart';
import 'package:rawasi_app_n/features/library/data/library_pdf.dart';
import 'package:rawasi_app_n/features/library/data/subject_item.dart';
import 'package:rawasi_app_n/features/library/data/library_repo.dart';
import 'package:rawasi_app_n/features/library/questions_view.dart';
import 'package:rawasi_app_n/root.dart';
import 'package:rawasi_app_n/shared/account_gate.dart';
import 'package:rawasi_app_n/shared/brand_backdrop.dart';
import 'package:rawasi_app_n/shared/auth_actions.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class SubjectsView extends StatefulWidget {
  const SubjectsView({super.key});

  @override
  State<SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<SubjectsView> {
  late Future<bool> _isSignedInFuture;
  late Future<Student?> _profileFuture;
  late Future<List<SubjectItem>> _subjectsFuture;

  /// Subjects currently being exported, keyed by id, so each card can show its
  /// own spinner without freezing the whole list.
  final Set<int> _exporting = {};

  @override
  void initState() {
    super.initState();
    _isSignedInFuture = isUserSignedIn();
    _profileFuture = _loadProfile();
    _subjectsFuture = LibraryRepo().fetchSubjects();
  }

  /// Re-fetches the list. Called after a subject run-through reports that it
  /// removed something, so an emptied subject disappears instead of lingering
  /// as a stale row with a stale count.
  void _refreshSubjects() {
    setState(() => _subjectsFuture = LibraryRepo().fetchSubjects());
  }

  Future<void> _openSubject(SubjectItem subject) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionsView(
          subjectId: subject.id,
          subjectName: subject.name,
        ),
      ),
    );
    if (changed == true) _refreshSubjects();
  }

  /// Builds the subject's PDF and opens the share/save sheet.
  ///
  /// The questions are fetched here rather than cached from the list, so the
  /// export always reflects what is actually saved right now.
  Future<void> _exportPdf(SubjectItem subject) async {
    if (_exporting.contains(subject.id)) return;
    setState(() => _exporting.add(subject.id));

    try {
      final List<ContentItem> questions =
          await LibraryRepo().fetchContent(subject.id, 'question');

      if (!mounted) return;

      if (questions.isEmpty) {
        // Never produce an empty document.
        _snack(LibraryPdf.emptyMessage, isError: true);
        _refreshSubjects();
        return;
      }

      await LibraryPdf.shareSubject(
        subjectName: subject.name,
        questions: questions,
      );
    } catch (e) {
      if (!mounted) return;
      _snack(
        e is StateError
            ? e.message
            : 'تعذّر إنشاء ملف PDF، حاول مرة أخرى',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _exporting.remove(subject.id));
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? AppColors.error600 : AppColors.brandSecondary,
        ),
      );
  }

  Future<Student?> _loadProfile() async {
    final isSignedIn = await isUserSignedIn();
    if (!isSignedIn) return null;
    try {
      return await ProfileRepository().fetchProfile();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const CustomText(
          text: 'المكتبة',
          color: AppColors.gray900,
          size: 18,
          weight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      body: BrandBackdrop(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: FutureBuilder<bool>(
            future: _isSignedInFuture,
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (authSnapshot.data != true) {
                return _buildLoginRequiredScreen();
              }

              return FutureBuilder<Student?>(
                future: _profileFuture,
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final profile = profileSnapshot.data;

                  if (profile == null || !profile.isActive) {
                    return _buildPendingReviewScreen(
                      profile,
                    ); // ← مررنا profile
                  }

                  return _buildSubjectsList();
                },
              );
            },
          ),
        ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildSubjectsList() {
    return FutureBuilder<List<SubjectItem>>(
      future: _subjectsFuture,
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
                const Gap(16),
                CustomText(
                  text: 'فشل تحميل المواد',
                  color: AppColors.error600,
                  size: 16,
                ),
                const Gap(8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: AppColors.gray600),
                ),
              ],
            ),
          );
        }

        final subjects = snapshot.data ?? [];
        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: AppColors.gray400,
                ),
                const Gap(16),
                CustomText(
                  text: 'مكتبتك فارغة',
                  color: AppColors.gray900,
                  size: 18,
                  weight: FontWeight.bold,
                ),
                const Gap(8),
                CustomText(
                  text: 'أضف الأسئلة التي تريد مراجعتها من داخل الدروس.',
                  color: AppColors.gray600,
                  size: 14,
                  align: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshSubjects(),
          child: ListView.separated(
            itemCount: subjects.length,
            separatorBuilder: (context, index) => const Gap(16),
            itemBuilder: (context, index) => _buildSubjectCard(subjects[index]),
          ),
        );
      },
    );
  }

  Widget _buildLoginRequiredScreen() {
    // Both ways in, same shared pair as every other pre-auth surface.
    return const AccountGate(
      reason: GateReason.signedOut,
      action: AuthActions(primary: AuthAction.register),
    );
  }

  /// free first month: this used to show "أكمل اشتراكك الآن" with a link to the
  /// receipt upload whenever is_upload_paid_certificate was false - which
  /// contradicted the courses screen and home for the very same student. There
  /// is no payment step now, so the one remaining blocker is admin activation.
  Widget _buildPendingReviewScreen(Student? profile) {
    return AccountGate(reason: gateFor(profile) ?? GateReason.underReview);
  }

  Widget _buildSubjectCard(SubjectItem subject) {
    final count = subject.savedQuestionsCount;
    final hasQuestions = count > 0;
    final isExporting = _exporting.contains(subject.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSubject(subject),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Same tinted brand badge as the courses cards.
                    const BrandIconBadge(icon: Icons.bookmark_outline),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: subject.name,
                            color: AppColors.gray900,
                            size: 17,
                            weight: FontWeight.w600,
                          ),
                          const Gap(4),
                          CustomText(
                            text: hasQuestions
                                ? '$count سؤال محفوظ'
                                : 'لا توجد أسئلة محفوظة',
                            color: AppColors.gray600,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                  ],
                ),
                const Gap(12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    // Disabled with nothing to export, so the student can
                    // never generate an empty PDF.
                    onPressed:
                        hasQuestions && !isExporting ? () => _exportPdf(subject) : null,
                    icon: isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.brandPrimary,
                            ),
                          )
                        : const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                            color: AppColors.brandPrimary,
                          ),
                    label: Text(
                      isExporting ? 'جارٍ التجهيز...' : 'استخراج PDF',
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: hasQuestions
                            ? AppColors.primary300
                            : AppColors.gray300,
                      ),
                      disabledForegroundColor: AppColors.gray400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
}
