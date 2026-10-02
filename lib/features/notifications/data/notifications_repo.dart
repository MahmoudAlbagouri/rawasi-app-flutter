// lib/features/notifications/data/notifications_repo.dart
//
// Tells the backend which device the signed-in student is on, so the dashboard
// can send them a push notification. Endpoints: POST / DELETE /device-token
// (DeviceTokenController in alazhar).

import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';

class NotificationsRepo {
  /// Used only if the server answers without a topic — an older backend.
  /// The real name comes from the server so the two sides cannot drift.
  static const String fallbackTopic = 'all_students';

  final ApiServices _api = ApiServices();

  /// Registers [token] for the signed-in student and returns the broadcast
  /// topic this device should subscribe to.
  Future<String> registerDevice(String token, {required String platform}) async {
    final result = await _api.post('/device-token', {
      'token': token,
      'platform': platform,
    });

    // ApiServices returns an ApiError instead of throwing it.
    if (result is ApiError) throw result;

    if (result is Map<String, dynamic> && result['success'] == true) {
      return topicFrom(result['data']);
    }

    throw ApiError(
      message: result is Map && result['message'] is String
          ? result['message'] as String
          : 'تعذّر تفعيل الإشعارات',
    );
  }

  /// Forgets [token] for the signed-in student. Called at sign-out, while the
  /// session is still valid — afterwards the request would be unauthenticated.
  Future<void> unregisterDevice(String token) async {
    final result = await _api.delete('/device-token', {'token': token});

    if (result is ApiError) throw result;
  }

  /// The topic from a /device-token response body, or [fallbackTopic].
  ///
  /// Tolerant on purpose: subscribing to the fallback is better than not
  /// subscribing at all, which would silently miss every broadcast.
  static String topicFrom(dynamic data) {
    if (data is Map) {
      final topic = data['topic']?.toString().trim();
      if (topic != null && topic.isNotEmpty) return topic;
    }

    return fallbackTopic;
  }
}
