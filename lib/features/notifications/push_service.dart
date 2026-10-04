// lib/features/notifications/push_service.dart
//
// Push notifications from the dashboard: to one student, or to all of them.
//
// HOW A MESSAGE REACHES A STUDENT
//   - To one student: the backend sends to every FCM token registered for them
//     (POST /device-token, done here after sign-in and on every launch).
//   - To everyone: the backend sends once to an FCM topic, which this device
//     subscribes to after sign-in. The topic name comes from the server.
//
// WHAT THE STUDENT SEES - a phone notification, in every state:
//   - App closed or in the background: Android posts it itself. The app does
//     not need to be running; this is what the `notification` block in every
//     message is for.
//   - App open: Android hands the message to the app instead and shows NOTHING
//     on its own. The app posts the same kind of phone notification itself
//     (flutter_local_notifications), on the same channel, so a message looks
//     the same whether the app is open or not - and stays in the notification
//     shade afterwards, instead of a dialog that is gone once dismissed.
//   - Tapping any of them opens the app on the full message in a dialog, since
//     a long message is cut short in the shade.
//
// NOTHING IS STORED. Messages are shown and forgotten, as the dashboard sends
// them; there is no inbox to sync.
//
// NEVER BREAKS THE APP. Firebase can be missing (no iOS config yet), the
// student can refuse the permission, the network can be down. Every entry point
// here swallows its own failures: push is an extra, never a reason sign-in,
// sign-out or start-up fails.

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rawasi_app_n/core/constants/app_colors.dart';
import 'package:rawasi_app_n/core/utils/pref_helper.dart';
import 'package:rawasi_app_n/features/notifications/data/notifications_repo.dart';

/// Runs in a separate background isolate when a message arrives while the app
/// is not in the foreground. Must be a top-level function.
///
/// There is nothing to do: notification messages are displayed by the system.
/// Firebase still has to be initialised in this isolate for the plugin to
/// finish handling the message.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// Lets a message be shown from anywhere, including before any screen has a
  /// context of its own. Handed to MaterialApp in main.dart.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _available = false;
  StreamSubscription<String>? _tokenRefresh;

  /// Posts phone notifications while the app is open. Null if it could not be
  /// set up, in which case foreground messages fall back to the dialog.
  FlutterLocalNotificationsPlugin? _local;

  /// The channel MainActivity.kt creates at HIGH importance (pops up as a
  /// banner). Must match it, the manifest, and services.fcm.android_channel.
  static const String channelId = 'rawasi_notifications';
  static const String channelName = 'إشعارات رواسي';

  /// Once, from main(), before runApp. Never throws.
  Future<void> init() async {
    try {
      // No options: on Android the google-services Gradle plugin compiles
      // android/app/google-services.json into the resources this reads. iOS has
      // no config yet, so this throws there and push is simply off.
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_showWhileOpen);
      FirebaseMessaging.onMessageOpenedApp.listen(_present);

      _available = true;

      await _initLocalNotifications();

      // Tapped while the app was fully closed: show it once the first screen
      // is up, since there is no navigator yet at this point.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _present(initial));
      }
    } catch (e) {
      _available = false;
      if (kDebugMode) debugPrint('Push notifications unavailable: $e');
    }
  }

  /// On every launch: re-register if a student is already signed in.
  ///
  /// FCM can rotate the token while the app is closed, and a re-install keeps
  /// the session but gets a new token, so registering only at sign-in would
  /// slowly lose devices.
  Future<void> syncIfSignedIn() async {
    final token = await PrefHelper.getToken();
    if (token == null || token.isEmpty) return;

    await syncForSignedInStudent();
  }

  /// After sign-in. Asks for permission, registers the device, subscribes to
  /// the broadcast topic. Never throws.
  Future<void> syncForSignedInStudent() async {
    if (!_available) return;

    try {
      final messaging = FirebaseMessaging.instance;

      // Android 13+ needs this permission to show anything at all. Refusing it
      // still registers the device: the token is valid, and the student can
      // turn notifications on from system settings later without signing in
      // again.
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token == null) return;

      await _register(token);

      _tokenRefresh ??= messaging.onTokenRefresh.listen((fresh) {
        _register(fresh).catchError((_) {});
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Push registration failed: $e');
    }
  }

  /// At sign-out — and BEFORE the session token is cleared, because removing
  /// the device from the backend is an authenticated request. Never throws,
  /// and gives up after a few seconds so a bad network cannot hang sign-out.
  Future<void> signOut() async {
    if (!_available) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await NotificationsRepo()
            .unregisterDevice(token)
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Best effort. The device is also moved automatically if someone else
      // signs in on it, so a missed unregister is not permanent.
    }

    try {
      await _tokenRefresh?.cancel();
      _tokenRefresh = null;

      // Deleting the FCM token also drops every topic subscription it had, so
      // this device stops getting broadcasts without having to remember which
      // topic it was on.
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  /// Sets up the plugin that posts phone notifications while the app is open,
  /// and opens the full message when one of those is tapped. Never throws:
  /// without it, foreground messages simply fall back to the in-app dialog.
  Future<void> _initLocalNotifications() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();

      await plugin.initialize(
        settings: const InitializationSettings(
          // The launcher icon. Android draws the small notification icon as a
          // single-colour silhouette, so a full-colour icon can appear as a
          // plain shape - a dedicated monochrome icon would fix that.
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _presentPayload(response.payload),
      );

      _local = plugin;

      // Tapped while the app was fully closed: the app was launched BY the
      // notification, so its payload arrives here rather than as a callback.
      final launch = await plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch!.notificationResponse?.payload;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _presentPayload(payload),
        );
      }
    } catch (e) {
      _local = null;
      if (kDebugMode) debugPrint('Local notifications unavailable: $e');
    }
  }

  /// A message arrived while the app is open. Android shows nothing for it, so
  /// post the same phone notification it would have shown with the app closed.
  Future<void> _showWhileOpen(RemoteMessage message) async {
    final content = PushMessageContent.from(
      title: message.notification?.title,
      body: message.notification?.body,
    );
    final local = _local;

    if (content == null) return;

    if (local == null) {
      _present(message);

      return;
    }

    try {
      await local.show(
        id: PushMessageContent.notificationId(message.messageId),
        title: content.title,
        body: content.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'رسائل من إدارة رواسي',
            importance: Importance.high,
            priority: Priority.high,
            // Long messages are shown in full when expanded in the shade,
            // instead of one truncated line.
            styleInformation: BigTextStyleInformation(content.body),
          ),
        ),
        payload: content.toPayload(),
      );
    } catch (_) {
      // The message must not be lost because the notification failed.
      _present(message);
    }
  }

  Future<void> _register(String fcmToken) async {
    final topic = await NotificationsRepo().registerDevice(
      fcmToken,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
    );

    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  /// Shows the full message in-app, after a tap on a Firebase notification.
  void _present(RemoteMessage message) {
    _presentContent(
      PushMessageContent.from(
        title: message.notification?.title,
        body: message.notification?.body,
      ),
    );
  }

  /// Same, after a tap on a notification the app posted itself.
  void _presentPayload(String? payload) {
    _presentContent(PushMessageContent.fromPayload(payload));
  }

  void _presentContent(PushMessageContent? content) {
    final context = navigatorKey.currentContext;

    if (content == null || context == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                content.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            content.body,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }
}

/// What a notification shows in-app, or null when there is nothing to show.
///
/// Separate so the rule is testable without Firebase: a message with neither a
/// title nor a body (a data-only message) must not open an empty dialog, and a
/// message with only a body still needs a title for the dialog header.
class PushMessageContent {
  final String title;
  final String body;

  const PushMessageContent(this.title, this.body);

  static const String defaultTitle = 'رسالة من رواسي';

  static PushMessageContent? from({String? title, String? body}) {
    final t = title?.trim() ?? '';
    final b = body?.trim() ?? '';

    if (t.isEmpty && b.isEmpty) return null;

    return PushMessageContent(t.isEmpty ? defaultTitle : t, b);
  }

  /// Carried on a notification the app posts, so a tap can reopen the full
  /// message without asking the server - there is nothing stored to ask.
  String toPayload() => jsonEncode({'title': title, 'body': body});

  /// The reverse. Tolerant: an unreadable payload opens nothing rather than
  /// crashing the app on a tap.
  static PushMessageContent? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;

      return from(
        title: decoded['title']?.toString(),
        body: decoded['body']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// A distinct Android notification id per message.
  ///
  /// Android REPLACES a notification posted with an id already on screen, so a
  /// fixed id would show only the latest of several messages - the very
  /// "only one arrived" symptom this work is fixing. Derived from FCM's message
  /// id (unique per send), falling back to the clock. Kept positive to stay a
  /// valid 32-bit notification id.
  static int notificationId(String? messageId) {
    final seed = (messageId != null && messageId.isNotEmpty)
        ? messageId.hashCode
        : DateTime.now().microsecondsSinceEpoch;

    return seed & 0x7fffffff;
  }
}
