import 'package:rawasi_app_n/features/exam/data/dayable.dart';

class DailyTaskItem {
  final int id;
  final Dayable dayable;

  DailyTaskItem({required this.id, required this.dayable});

  factory DailyTaskItem.fromJson(Map<String, dynamic> json) {
    return DailyTaskItem(
      id: json['id'] ?? 0,
      dayable: Dayable.fromJson(json['dayable'] ?? {}),
    );
  }
}
