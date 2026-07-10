import 'package:rawasi_app_n/features/exam/data/daily_task_item.dart';

class DailyTaskResponse {
  final bool success;
  final List<DailyTaskItem> data;
  final dynamic additionalData;
  final String? message;

  DailyTaskResponse({
    required this.success,
    required this.data,
    this.additionalData,
    this.message,
  });

  factory DailyTaskResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List?;
    final tasks =
        dataList?.map((e) => DailyTaskItem.fromJson(e)).toList() ?? [];

    return DailyTaskResponse(
      success: json['success'] ?? false,
      data: tasks,
      additionalData: json['addtionalData'], // مكتوبة خطأ في API
      message: json['message'],
    );
  }
}
