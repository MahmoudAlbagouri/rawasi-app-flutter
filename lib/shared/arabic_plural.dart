// lib/shared/arabic_plural.dart
//
// Arabic counted nouns. Arabic does not have one plural form, and the existing
// cards had quietly settled on the singular for every count ("5 نقطة"), which
// reads wrong. One helper so the statistics screen stops inventing a style per
// card.
//
// The rule for a counted noun (تمييز العدد):
//   1        → singular            يوم
//   2        → dual                يومان
//   3 – 10   → plural              أيام
//   11 +     → singular again      يومًا   (accusative singular)
//   0        → plural              أيام
//
// The number itself is rendered in Western digits, matching the rest of the
// app.

/// Formats [count] with the right Arabic form of the noun.
///
/// For 1 and 2 the number is normally dropped in natural Arabic ("يوم واحد" is
/// stilted next to a bare "يوم"), so [dropNumberForOneAndTwo] omits it.
String arabicCount(
  int count, {
  required String singular,
  required String dual,
  required String plural,
  String? accusativeSingular,
  bool dropNumberForOneAndTwo = true,
}) {
  final n = count.abs();
  final eleven = accusativeSingular ?? singular;

  if (n == 1) return dropNumberForOneAndTwo ? singular : '$n $singular';
  if (n == 2) return dropNumberForOneAndTwo ? dual : '$n $dual';
  // 0 takes the plural in ordinary usage ("0 أيام"), alongside 3-10.
  if (n == 0 || (n >= 3 && n <= 10)) return '$n $plural';
  return '$n $eleven';
}

/// "يوم" / "يومان" / "5 أيام" / "15 يومًا"
String arabicDays(int count) => arabicCount(
      count,
      singular: 'يوم',
      dual: 'يومان',
      plural: 'أيام',
      accusativeSingular: 'يومًا',
    );

/// "نقطة" / "نقطتان" / "5 نقاط" / "15 نقطة"
String arabicPoints(int count) => arabicCount(
      count,
      singular: 'نقطة',
      dual: 'نقطتان',
      plural: 'نقاط',
      dropNumberForOneAndTwo: false,
    );

/// "درس" / "درسان" / "5 دروس" / "15 درسًا"
String arabicLessons(int count) => arabicCount(
      count,
      singular: 'درس',
      dual: 'درسان',
      plural: 'دروس',
      accusativeSingular: 'درسًا',
      dropNumberForOneAndTwo: false,
    );

const List<String> _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

/// "2026-09-24" → "24 سبتمبر 2026".
///
/// The API sends raw Y-m-d; showing that to a student is an ISO string, not a
/// date. Returns null for anything unparseable so callers can fall back rather
/// than print a broken string.
String? arabicDate(String? isoDate) {
  if (isoDate == null || isoDate.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(isoDate.trim());
  if (parsed == null) return null;
  return '${parsed.day} ${_arabicMonths[parsed.month - 1]} ${parsed.year}';
}
