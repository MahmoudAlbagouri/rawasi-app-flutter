// lib/features/auth/data/registration_data.dart
//
// Carries the registration flow's collected state across screens:
// Step1 (grade) -> Step2 (phone/password) -> OTP -> Complete profile A/B.
//
// free first month: the plan, referral and discount fields are gone from
// step 1/2, and the profile no longer collects is_final_secondary, term_level,
// email, quran_level or supervisors.
//
// Held for the whole flow by a single RegistrationDraft, which is what makes
// back-navigation lossless - see registration_draft.dart.

class RegistrationData {
  // Step 1 — grade
  final String academicYear; // "1" | "2" | "3"

  // Step 2 — credentials
  final String phone1;
  final String password;
  final String confirmPassword;

  // Complete-profile A — personal info
  final String firstName;
  final String lastName;
  final String gender;
  final String birthDate;
  final String? schoolBranch;
  final String madhab;

  // Complete-profile B — institute & contact
  final String instituteName;
  final String governorate;
  final String city;
  final String? phone2;
  final bool isWhatsapp;

  const RegistrationData({
    this.academicYear = '',
    this.phone1 = '',
    this.password = '',
    this.confirmPassword = '',
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.birthDate = '',
    this.schoolBranch,
    this.madhab = '',
    this.instituteName = '',
    this.governorate = '',
    this.city = '',
    this.phone2,
    this.isWhatsapp = true,
  });

  RegistrationData copyWith({
    String? academicYear,
    String? phone1,
    String? password,
    String? confirmPassword,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    String? schoolBranch,
    String? madhab,
    String? instituteName,
    String? governorate,
    String? city,
    String? phone2,
    bool? isWhatsapp,
  }) {
    return RegistrationData(
      academicYear: academicYear ?? this.academicYear,
      phone1: phone1 ?? this.phone1,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      schoolBranch: schoolBranch ?? this.schoolBranch,
      madhab: madhab ?? this.madhab,
      instituteName: instituteName ?? this.instituteName,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      phone2: phone2 ?? this.phone2,
      isWhatsapp: isWhatsapp ?? this.isWhatsapp,
    );
  }
}
