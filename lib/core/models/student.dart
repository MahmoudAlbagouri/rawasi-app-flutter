// Unified Student model matching `StudentResource` on the backend.
// Returned (wrapped in `data`) by /profile, and nested under `data.student`
// by /login and /check-otp (which also carry a sibling `data.token`).

class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? gender;
  final String? birthDate;
  final bool isFinalSecondary;
  final String? schoolBranch;
  final String? madhab;
  final String? instituteName;
  final String? governorate;
  final String? city;
  final String phone1;
  final String? phone2;
  final bool isWhatsapp;
  final int? quranLevel;
  final String? paidCertificate;
  final bool isUploadPaidCertificate;
  final bool isActive;
  final bool isProfileCompleted;
  final String academicYear;
  final int? planId;
  final String? termLevel;
  final String? supervisor1Name;
  final String? supervisor1Relation;
  final String? supervisor1Phone;
  final String? supervisor2Name;
  final String? supervisor2Relation;
  final String? supervisor2Phone;
  final String? createdAt;
  final String? updatedAt;
  final String? activeAt;
  final int availableDays;
  final double progress;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.gender,
    this.birthDate,
    required this.isFinalSecondary,
    this.schoolBranch,
    this.madhab,
    this.instituteName,
    this.governorate,
    this.city,
    required this.phone1,
    this.phone2,
    required this.isWhatsapp,
    this.quranLevel,
    this.paidCertificate,
    required this.isUploadPaidCertificate,
    required this.isActive,
    required this.isProfileCompleted,
    required this.academicYear,
    this.planId,
    this.termLevel,
    this.supervisor1Name,
    this.supervisor1Relation,
    this.supervisor1Phone,
    this.supervisor2Name,
    this.supervisor2Relation,
    this.supervisor2Phone,
    this.createdAt,
    this.updatedAt,
    this.activeAt,
    required this.availableDays,
    required this.progress,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Student.fromJson(Map<String, dynamic> json) {
    bool _bool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    double _double(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse('$v') ?? 0.0;
    }

    return Student(
      id: _int(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] as String?,
      isFinalSecondary: _bool(json['is_final_secondary']),
      schoolBranch: json['school_branch'] as String?,
      madhab: json['madhab'] as String?,
      instituteName: json['institute_name'] as String?,
      governorate: json['governorate'] as String?,
      city: json['city'] as String?,
      phone1: json['phone1'] as String? ?? '',
      phone2: json['phone2'] as String?,
      isWhatsapp: _bool(json['is_whatsapp']),
      quranLevel: json['quran_level'] == null ? null : _int(json['quran_level']),
      paidCertificate: json['paid_certificate'] as String?,
      isUploadPaidCertificate: _bool(json['is_upload_paid_certificate']),
      isActive: _bool(json['is_active']),
      isProfileCompleted: _bool(json['is_profile_completed']),
      academicYear: json['academic_year']?.toString() ?? '',
      planId: json['plan_id'] == null ? null : _int(json['plan_id']),
      termLevel: json['term_level']?.toString(),
      supervisor1Name: json['supervisor1_name'] as String?,
      supervisor1Relation: json['supervisor1_relation'] as String?,
      supervisor1Phone: json['supervisor1_phone'] as String?,
      supervisor2Name: json['supervisor2_name'] as String?,
      supervisor2Relation: json['supervisor2_relation'] as String?,
      supervisor2Phone: json['supervisor2_phone'] as String?,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      activeAt: json['active_at']?.toString(),
      availableDays: json['available_days'] == null ? 0 : _int(json['available_days']),
      progress: _double(json['progress'] ?? 0),
    );
  }

  /// True for a Grade-3 student on the 30-day monthly plan whose window has lapsed.
  bool get isSubscriptionExpired {
    if (academicYear != '3') return false;
    if (availableDays != 30) return false;
    if (activeAt == null) return false;
    final active = DateTime.tryParse(activeAt!);
    if (active == null) return false;
    return active.add(const Duration(days: 30)).isBefore(DateTime.now());
  }
}
