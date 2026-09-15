class Course {
  final int id;
  final String name;
  final String academicYear;
  final String madhab;

  Course({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.madhab,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      academicYear: json['academic_year']?.toString() ?? 'all',
      madhab: json['madhab']?.toString() ?? 'all',
    );
  }
}
