import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/notifications/data/notifications_repo.dart';
import 'package:rawasi_app_n/features/notifications/push_service.dart';

/// The pieces of push notifications that do not need Firebase to run.
///
/// The Firebase calls themselves cannot run in a unit test, so the rules worth
/// pinning live in plain functions: which topic to subscribe to, and what a
/// message shows when it arrives.
void main() {
  group('the broadcast topic', () {
    test('comes from the server, so the two sides cannot drift', () {
      expect(NotificationsRepo.topicFrom({'topic': 'grade_1_students'}), 'grade_1_students');
    });

    test('falls back rather than leaving the device unsubscribed', () {
      // Subscribing to the default is better than subscribing to nothing, which
      // would silently miss every broadcast.
      expect(NotificationsRepo.topicFrom(null), NotificationsRepo.fallbackTopic);
      expect(NotificationsRepo.topicFrom(const {}), NotificationsRepo.fallbackTopic);
      expect(NotificationsRepo.topicFrom({'topic': '  '}), NotificationsRepo.fallbackTopic);
      expect(NotificationsRepo.topicFrom('not a map'), NotificationsRepo.fallbackTopic);
    });

    test('the fallback matches the backend default', () {
      // config/services.php -> fcm.broadcast_topic defaults to this too.
      expect(NotificationsRepo.fallbackTopic, 'all_students');
    });
  });

  group('what a message shows', () {
    test('title and body as sent', () {
      final c = PushMessageContent.from(title: 'إعلان', body: 'تم إضافة دروس جديدة');

      expect(c, isNotNull);
      expect(c!.title, 'إعلان');
      expect(c.body, 'تم إضافة دروس جديدة');
    });

    test('a body with no title still gets a header', () {
      final c = PushMessageContent.from(title: null, body: 'نص فقط');

      expect(c!.title, PushMessageContent.defaultTitle);
      expect(c.body, 'نص فقط');
    });

    test('a message with nothing to show opens no dialog', () {
      // A data-only message must not pop an empty box over a lesson.
      expect(PushMessageContent.from(title: null, body: null), isNull);
      expect(PushMessageContent.from(title: '  ', body: ''), isNull);
    });

    test('surrounding whitespace is trimmed', () {
      final c = PushMessageContent.from(title: '  عنوان  ', body: '\nنص\n');

      expect(c!.title, 'عنوان');
      expect(c.body, 'نص');
    });
  });

  group('notifications posted while the app is open', () {
    test('each message gets its own id, so they stack instead of replacing', () {
      // Android REPLACES a notification posted with an id already showing. A
      // fixed id would leave only the latest of several messages on screen -
      // exactly the reported "only one message arrived".
      final ids = {
        for (final id in [
          '0:1790953003832124%7cff39ae7cff39ae',
          '0:1790953003832125%7cff39ae7cff39ae',
          '0:1790953003832126%7cff39ae7cff39ae',
        ])
          PushMessageContent.notificationId(id),
      };

      expect(ids.length, 3);
    });

    test('the same message always maps to the same id', () {
      // A redelivered message updates its own notification rather than
      // posting a duplicate beside it.
      const id = '0:1790953003832124%7cff39ae7cff39ae';

      expect(
        PushMessageContent.notificationId(id),
        PushMessageContent.notificationId(id),
      );
    });

    test('ids are valid positive 32-bit values', () {
      for (final id in ['a', 'zzzzzzzzzzzz', '0:1:2', '', null]) {
        final n = PushMessageContent.notificationId(id);
        expect(n, inInclusiveRange(0, 0x7fffffff), reason: 'for $id');
      }
    });
  });

  group('tapping a notification', () {
    test('reopens exactly the message it showed', () {
      const original = PushMessageContent('احمد مجدي', 'رسالة طويلة\nمن سطرين');

      final restored = PushMessageContent.fromPayload(original.toPayload());

      expect(restored!.title, original.title);
      expect(restored.body, original.body);
    });

    test('an unreadable payload opens nothing instead of crashing', () {
      expect(PushMessageContent.fromPayload(null), isNull);
      expect(PushMessageContent.fromPayload(''), isNull);
      expect(PushMessageContent.fromPayload('not json'), isNull);
      expect(PushMessageContent.fromPayload('[1,2]'), isNull);
      expect(PushMessageContent.fromPayload('{}'), isNull);
    });
  });
}
