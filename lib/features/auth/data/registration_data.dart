// lib/features/auth/data/registration_data.dart

class RegistrationData {
  final String email;
  final String password;
  final String confirmPassword;

  final String firstName;
  final String lastName;
  final String mainPhone;
  final String? secondaryPhone;

  final String gender;
  final String branch;
  final String birthDate;

  final String instituteName;
  final String governorate;
  final String city;
  final String supervisorName;
  final String supervisorRelation;
  final String supervisorPhone;
  final String? supervisor2Name;
  final String? supervisor2Relation;
  final String? supervisor2Phone;

  // 👇 الحقل الجديد: كود الإحالة (اختياري)
  final String? referralCode;

  RegistrationData({
    required this.email,
    required this.password,
    required this.confirmPassword,

    required this.firstName,
    required this.lastName,
    required this.mainPhone,
    this.secondaryPhone,

    required this.gender,
    required this.branch,
    required this.birthDate,

    required this.instituteName,
    required this.governorate,
    required this.city,
    required this.supervisorName,
    required this.supervisorRelation,
    required this.supervisorPhone,
    this.supervisor2Name,
    this.supervisor2Relation,
    this.supervisor2Phone,

    this.referralCode, // ← تمريره في الـ constructor
  });
}
