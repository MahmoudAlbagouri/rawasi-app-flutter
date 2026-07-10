// lib/core/models/student_profile.dart

class StudentProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String gender;
  final String birthDate;
  final bool isFinalSecondary;
  final String? schoolBranch;
  final String? doctrine;
  final String instituteName;
  final String governorate;
  final String city;
  final String? phone1;
  final String? phone2;
  final bool isWhatsapp;
  final String? quranLevel;
  final bool isUploadPaidCertificate;
  final bool isActive;
  final String? supervisor1Name;
  final String? supervisor1Relation;
  final String? supervisor1Phone;
  final String? supervisor2Name;
  final String? supervisor2Relation;
  final String? supervisor2Phone;
  final String createdAt;
  final String updatedAt;
  final int currentDay;
  final int expectedCurrentDay;
  final bool isVacation;
  final bool isExamDay;
  final bool isScheduleExamDay;
  final String activeAt;
  final double progress;

  StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.birthDate,
    required this.isFinalSecondary,
    this.schoolBranch,
    this.doctrine,
    required this.instituteName,
    required this.governorate,
    required this.city,
    this.phone1,
    this.phone2,
    required this.isWhatsapp,
    this.quranLevel,
    required this.isUploadPaidCertificate,
    required this.isActive,
    this.supervisor1Name,
    this.supervisor1Relation,
    this.supervisor1Phone,
    this.supervisor2Name,
    this.supervisor2Relation,
    this.supervisor2Phone,
    required this.createdAt,
    required this.updatedAt,
    required this.currentDay,
    required this.expectedCurrentDay,
    required this.isVacation,
    required this.isExamDay,
    required this.isScheduleExamDay,
    required this.activeAt,
    required this.progress,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    String _str(dynamic v) => v?.toString().trim() ?? '';
    bool _bool(dynamic v) => v == true;
    int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    double _double(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      final numVal = num.tryParse('$v');
      return numVal?.toDouble() ?? 0.0;
    }

    return StudentProfile(
      id: _int(data['id']),
      firstName: _str(data['first_name']),
      lastName: _str(data['last_name']),
      email: _str(data['email']),
      gender: _str(data['gender']),
      birthDate: _str(data['birth_date']),
      isFinalSecondary: _bool(data['is_final_secondary']),
      schoolBranch: data['school_branch'] as String?,
      doctrine: data['doctrine'] as String?,
      instituteName: _str(data['institute_name']),
      governorate: _str(data['governorate']),
      city: _str(data['city']),
      phone1: data['phone1'] as String?,
      phone2: data['phone2'] as String?,
      isWhatsapp: _bool(data['is_whatsapp']),
      quranLevel: data['quran_level'] as String?,
      isUploadPaidCertificate: _bool(data['is_upload_paid_certificate']),
      isActive: _bool(data['is_active']),
      supervisor1Name: data['supervisor1_name'] as String?,
      supervisor1Relation: data['supervisor1_relation'] as String?,
      supervisor1Phone: data['supervisor1_phone'] as String?,
      supervisor2Name: data['supervisor2_name'] as String?,
      supervisor2Relation: data['supervisor2_relation'] as String?,
      supervisor2Phone: data['supervisor2_phone'] as String?,
      createdAt: _str(data['created_at']),
      updatedAt: _str(data['updated_at']),
      currentDay: _int(data['current_day']),
      expectedCurrentDay: _int(data['expected_current_day']),
      isVacation: _bool(data['is_vacation']),
      isExamDay: _bool(
        data['is_exame_day'],
      ), // مكتوبة خطأ في API: exame وليس exam
      isScheduleExamDay: _bool(data['is_schedule_exame_day']),
      activeAt: _str(data['active_at']),
      progress: _double(data['progress']),
    );
  }
}
