// student_model.dart

class UserModel {
  final String email;

  final String firstName;
  final String lastName;
  final String gender;
  final String birthDate;
  final bool isFinalSecondary;
  final String schoolBranch;
  final String instituteName;
  final String governorate;
  final String city;
  final String phone1;
  final String? phone2;
  final String? referralCode;
  final String? token;
  final bool isWhatsapp;
  final String quranLevel;
  final String doctrine;
  final String supervisorName;
  final String supervisorRelation;
  final String supervisorPhone;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    required this.isFinalSecondary,
    required this.schoolBranch,
    required this.instituteName,
    required this.governorate,
    required this.city,
    required this.phone1,
    this.phone2,
    this.referralCode,
    this.token,
    required this.isWhatsapp,
    required this.email,
    required this.quranLevel,
    required this.doctrine,
    required this.supervisorName,
    required this.supervisorRelation,
    required this.supervisorPhone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. التحقق من حالة النجاح
    final success = json['success'] as bool? ?? false;

    if (!success) {
      final message =
          json['message'] as String? ?? 'فشل تسجيل الدخول: تحقق من بياناتك.';
      throw Exception(message);
    }

    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('البيانات (data) غير موجودة في الاستجابة');
    }

    final studentData = data['student'] as Map<String, dynamic>?;
    if (studentData == null) {
      throw Exception(
        'بيانات الطالب (student) غير موجودة في الاستجابة - رغم نجاح العملية الظاهري.',
      );
    }

    return UserModel(
      firstName: studentData['first_name'] as String? ?? '',
      lastName: studentData['last_name'] as String? ?? '',
      gender: studentData['gender'] as String? ?? '',
      birthDate: studentData['birth_date'] as String? ?? '',
      isFinalSecondary: _parseBool(studentData['is_final_secondary']),
      schoolBranch: studentData['school_branch'] as String? ?? '',
      instituteName: studentData['institute_name'] as String? ?? '',
      governorate: studentData['governorate'] as String? ?? '',
      city: studentData['city'] as String? ?? '',
      phone1: studentData['phone1'] as String? ?? '',
      phone2: studentData['phone2'] != null
          ? studentData['phone2'] as String?
          : null,
      referralCode: studentData['referral_code'] != null
          ? studentData['referral_code'] as String?
          : null,
      token: data['token'] as String?, // ← التوكن من 'data'
      isWhatsapp: _parseBool(studentData['is_whatsapp']),
      email: studentData['email'] as String? ?? '',
      quranLevel: studentData['quran_level'] as String? ?? '',
      doctrine: studentData['doctrine'] as String? ?? '',
      supervisorName: studentData['supervisor1_name'] as String? ?? '',
      supervisorRelation: studentData['supervisor1_relation'] as String? ?? '',
      supervisorPhone: studentData['supervisor1_phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'birth_date': birthDate,
      'is_final_secondary': isFinalSecondary ? 1 : 0,
      'school_branch': schoolBranch,
      'institute_name': instituteName,
      'governorate': governorate,
      'city': city,
      'phone1': phone1,
      'phone2': phone2,
      'token': token,
      'is_whatsapp': isWhatsapp ? 1 : 0,
      'email': email,
      'quran_level': quranLevel,
      'doctrine': doctrine,
      'supervisor1_name': supervisorName,
      'supervisor1_relation': supervisorRelation,
      'supervisor1_phone': supervisorPhone,
    };
  }

  // مساعدة لتحويل القيم النصية أو الرقمية إلى bool
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value == 'true' || value == 'True';
    }
    return false;
  }
}
