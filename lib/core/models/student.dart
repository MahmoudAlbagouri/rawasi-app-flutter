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

    // Laravel returns raw column types, so a numeric column (quran_level) or a
    // numeric-looking value in a text column arrives as int, not String. Casting
    // those with `as String?` throws and takes the whole login down.
    String? _str(dynamic v) => v?.toString();

    return Student(
      id: _int(json['id']),
      firstName: _str(json['first_name']) ?? '',
      lastName: _str(json['last_name']) ?? '',
      email: _str(json['email']),
      gender: _str(json['gender']),
      birthDate: _str(json['birth_date']),
      isFinalSecondary: _bool(json['is_final_secondary']),
      schoolBranch: _str(json['school_branch']),
      madhab: _str(json['madhab']),
      instituteName: _str(json['institute_name']),
      governorate: _str(json['governorate']),
      city: _str(json['city']),
      phone1: _str(json['phone1']) ?? '',
      phone2: _str(json['phone2']),
      isWhatsapp: _bool(json['is_whatsapp']),
      quranLevel: json['quran_level'] == null ? null : _int(json['quran_level']),
      paidCertificate: _str(json['paid_certificate']),
      isUploadPaidCertificate: _bool(json['is_upload_paid_certificate']),
      isActive: _bool(json['is_active']),
      isProfileCompleted: _bool(json['is_profile_completed']),
      academicYear: _str(json['academic_year']) ?? '',
      planId: json['plan_id'] == null ? null : _int(json['plan_id']),
      termLevel: _str(json['term_level']),
      supervisor1Name: _str(json['supervisor1_name']),
      supervisor1Relation: _str(json['supervisor1_relation']),
      supervisor1Phone: _str(json['supervisor1_phone']),
      supervisor2Name: _str(json['supervisor2_name']),
      supervisor2Relation: _str(json['supervisor2_relation']),
      supervisor2Phone: _str(json['supervisor2_phone']),
      createdAt: _str(json['created_at']),
      updatedAt: _str(json['updated_at']),
      activeAt: _str(json['active_at']),
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
