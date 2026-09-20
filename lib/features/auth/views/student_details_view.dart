// lib/features/auth/views/student_details_view.dart
//
// Read-only view of everything GET /api/student/profile returns, grouped the
// way the student thinks about it: who they are, where they study, their
// subscription, and their guardians.

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/models/student.dart';
import 'package:rawasi_app_n/core/profile/profile_repository.dart';
import 'package:rawasi_app_n/shared/custom_text.dart';

class StudentDetailsView extends StatefulWidget {
  const StudentDetailsView({super.key});

  @override
  State<StudentDetailsView> createState() => _StudentDetailsViewState();
}

class _StudentDetailsViewState extends State<StudentDetailsView> {
  late Future<Student> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileRepository().fetchProfile();
  }

  void _reload() => setState(() => _future = ProfileRepository().fetchProfile());

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
        title: const Text(
          'بياناتي',
          style: TextStyle(
            color: AppColors.gray900,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<Student>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _error();
            }
            final s = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(s),
                  const Gap(16),
                  _section('البيانات الشخصية', Icons.person_outline, [
                    _row('الاسم', s.fullName),
                    _row('النوع', _gender(s.gender)),
                    _row('تاريخ الميلاد', s.birthDate),
                    _row('رقم الهاتف', s.phone1),
                    _row('واتساب على الرقم الأساسي', s.isWhatsapp ? 'نعم' : 'لا'),
                    _row('رقم هاتف إضافي', s.phone2),
                    _row('البريد الإلكتروني', s.email),
                  ]),
                  _section('البيانات الدراسية', Icons.school_outlined, [
                    _row('الصف الدراسي', _grade(s.academicYear)),
                    _row('الفصل الدراسي', _term(s.termLevel)),
                    _row('المذهب', _madhab(s.madhab)),
                    _row('الشعبة', _branch(s.schoolBranch)),
                    _row('السنة الأخيرة من الثانوية', s.isFinalSecondary ? 'نعم' : 'لا'),
                    _row('المعهد', s.instituteName),
                    _row('المحافظة', s.governorate),
                    _row('المدينة', s.city),
                    _row('الأجزاء المحفوظة من القرآن',
                        s.quranLevel == null ? null : '${s.quranLevel} جزء'),
                  ]),
                  _section('الاشتراك', Icons.verified_user_outlined, [
                    _row('حالة الحساب', s.isActive ? 'مفعّل' : 'غير مفعّل',
                        valueColor: s.isActive ? AppColors.success700 : AppColors.error600),
                    _row('استكمال الملف الشخصي', s.isProfileCompleted ? 'مكتمل' : 'غير مكتمل'),
                    _row('إيصال الدفع', s.isUploadPaidCertificate ? 'تم الرفع' : 'لم يُرفع'),
                    _row('تاريخ التفعيل', _date(s.activeAt)),
                    _row('مدة الاشتراك',
                        s.availableDays > 0 ? '${s.availableDays} يوم' : null),
                    _row('نسبة الإنجاز', '${_trim(s.progress)}%'),
                  ]),
                  _section('ولي الأمر', Icons.family_restroom_outlined, [
                    _row('الاسم', s.supervisor1Name),
                    _row('صلة القرابة', s.supervisor1Relation),
                    _row('رقم الهاتف', s.supervisor1Phone),
                  ]),
                  if (s.supervisor2Name != null && s.supervisor2Name!.isNotEmpty)
                    _section('ولي أمر ثانٍ', Icons.family_restroom_outlined, [
                      _row('الاسم', s.supervisor2Name),
                      _row('صلة القرابة', s.supervisor2Relation),
                      _row('رقم الهاتف', s.supervisor2Phone),
                    ]),
                  const Gap(8),
                  Center(
                    child: CustomText(
                      text: 'عضو منذ ${_date(s.createdAt) ?? '—'}',
                      color: AppColors.gray500,
                      size: 12,
                    ),
                  ),
                  const Gap(16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pieces
  // ---------------------------------------------------------------------------

  Widget _header(Student s) {
    final initials = [
      if (s.firstName.isNotEmpty) s.firstName[0],
      if (s.lastName.isNotEmpty) s.lastName[0],
    ].join();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              initials.isEmpty ? 'ط' : initials,
              style: const TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: s.fullName.isEmpty ? 'طالب' : s.fullName,
                  color: Colors.white,
                  size: 18,
                  weight: FontWeight.bold,
                ),
                const Gap(4),
                CustomText(
                  text: '${_grade(s.academicYear)} · ${_madhab(s.madhab) ?? '—'}',
                  color: Colors.white.withOpacity(0.85),
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget?> rows) {
    final visible = rows.whereType<Widget>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.brandPrimary),
                  const Gap(8),
                  CustomText(
                    text: title,
                    color: AppColors.brandPrimary,
                    size: 15,
                    weight: FontWeight.bold,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),
            ...visible,
          ],
        ),
      ),
    );
  }

  /// A label/value line. Returns null (and is dropped) when the value is
  /// empty, so the student never sees a row that says nothing.
  Widget? _row(String label, String? value, {Color? valueColor}) {
    if (value == null || value.trim().isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: CustomText(text: label, color: AppColors.gray600, size: 13),
          ),
          const Gap(12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: valueColor ?? AppColors.gray900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: AppColors.gray400),
            const Gap(16),
            CustomText(
              text: 'تعذّر تحميل بياناتك',
              color: AppColors.gray700,
              size: 15,
            ),
            const Gap(20),
            ElevatedButton(
              onPressed: _reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Value labels — mirror the backend enums
  // ---------------------------------------------------------------------------

  String _grade(String year) => switch (year) {
        '1' => 'الصف الأول الثانوي',
        '2' => 'الصف الثاني الثانوي',
        '3' => 'الصف الثالث الثانوي',
        _ => year.isEmpty ? '—' : year,
      };

  String? _term(String? term) => switch (term) {
        '1' => 'الفصل الأول',
        '2' => 'الفصل الثاني',
        _ => null,
      };

  String? _madhab(String? m) => switch (m) {
        'hanafi' => 'حنفي',
        'maliki' => 'مالكي',
        'shafii' => 'شافعي',
        'hanbali' => 'حنبلي',
        _ => null,
      };

  String? _gender(String? g) => switch (g) {
        'male' => 'ذكر',
        'female' => 'أنثى',
        _ => null,
      };

  String? _branch(String? b) => switch (b) {
        'science' => 'علمي',
        'literature' => 'أدبي',
        _ => null,
      };

  /// "2026-06-01T10:00:00.000000Z" → "2026-06-01".
  String? _date(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toIso8601String().split('T').first ?? iso;
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
