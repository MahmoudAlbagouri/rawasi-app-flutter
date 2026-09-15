// lib/features/auth/data/registration_data.dart
//
// Carries the registration flow's collected state across screens:
// Step1 (grade + plan) -> Step2 (phone/password) -> OTP -> Complete profile A/B.

class RegistrationData {
  // Step 1 — grade & plan
  final String academicYear; // "1" | "2" | "3"
  final int planId;

  // Step 2 — credentials
  final String phone1;
  final String password;
  final String confirmPassword;
  final String? referralCode;
  final String? discountCode;

  // Complete-profile A — personal info
  final String firstName;
  final String lastName;
  final String gender;
  final String birthDate;
  final bool isFinalSecondary;
  final String? schoolBranch;
  final String madhab;
  final String? termLevel;

  // Complete-profile B — institute & supervisors
  final String instituteName;
  final String governorate;
  final String city;
  final String? email;
  final String? phone2;
  final bool isWhatsapp;
  final int? quranLevel;
  final String supervisor1Name;
  final String supervisor1Relation;
  final String supervisor1Phone;
  final String? supervisor2Name;
  final String? supervisor2Relation;
  final String? supervisor2Phone;

  const RegistrationData({
    this.academicYear = '',
    this.planId = 0,
    this.phone1 = '',
    this.password = '',
    this.confirmPassword = '',
    this.referralCode,
    this.discountCode,
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.birthDate = '',
    this.isFinalSecondary = false,
    this.schoolBranch,
    this.madhab = '',
    this.termLevel,
    this.instituteName = '',
    this.governorate = '',
    this.city = '',
    this.email,
    this.phone2,
    this.isWhatsapp = true,
    this.quranLevel,
    this.supervisor1Name = '',
    this.supervisor1Relation = '',
    this.supervisor1Phone = '',
    this.supervisor2Name,
    this.supervisor2Relation,
    this.supervisor2Phone,
  });

  RegistrationData copyWith({
    String? academicYear,
    int? planId,
    String? phone1,
    String? password,
    String? confirmPassword,
    String? referralCode,
    String? discountCode,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    bool? isFinalSecondary,
    String? schoolBranch,
    String? madhab,
    String? termLevel,
    String? instituteName,
    String? governorate,
    String? city,
    String? email,
    String? phone2,
    bool? isWhatsapp,
    int? quranLevel,
    String? supervisor1Name,
    String? supervisor1Relation,
    String? supervisor1Phone,
    String? supervisor2Name,
    String? supervisor2Relation,
    String? supervisor2Phone,
  }) {
    return RegistrationData(
      academicYear: academicYear ?? this.academicYear,
      planId: planId ?? this.planId,
      phone1: phone1 ?? this.phone1,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      referralCode: referralCode ?? this.referralCode,
      discountCode: discountCode ?? this.discountCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      isFinalSecondary: isFinalSecondary ?? this.isFinalSecondary,
      schoolBranch: schoolBranch ?? this.schoolBranch,
      madhab: madhab ?? this.madhab,
      termLevel: termLevel ?? this.termLevel,
      instituteName: instituteName ?? this.instituteName,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      email: email ?? this.email,
      phone2: phone2 ?? this.phone2,
      isWhatsapp: isWhatsapp ?? this.isWhatsapp,
      quranLevel: quranLevel ?? this.quranLevel,
      supervisor1Name: supervisor1Name ?? this.supervisor1Name,
      supervisor1Relation: supervisor1Relation ?? this.supervisor1Relation,
      supervisor1Phone: supervisor1Phone ?? this.supervisor1Phone,
      supervisor2Name: supervisor2Name ?? this.supervisor2Name,
      supervisor2Relation: supervisor2Relation ?? this.supervisor2Relation,
      supervisor2Phone: supervisor2Phone ?? this.supervisor2Phone,
    );
  }
}
