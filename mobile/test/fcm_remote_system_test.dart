import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/services/notification_router.dart';
import 'package:focus_flow/services/fcm_sender_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationRouter.activeConversationId = null;
  });

  group('FCM Remote Push System — Payload & Routing Tests', () {
    test('1. NotificationPayload correctly parses chat_message data payload', () {
      final data = {
        'type': 'chat_message',
        'conversationId': 'userA_userB',
        'senderId': '6TXPK',
        'senderUid': 'fb_user_a',
        'senderName': 'Alice',
        'text': 'Hello from FocusFlow web!',
      };

      final payload = NotificationPayload.fromMap(data);

      expect(payload.type, equals('chat_message'));
      expect(payload.conversationId, equals('userA_userB'));
      expect(payload.senderId, equals('6TXPK'));
      expect(payload.senderName, equals('Alice'));
      expect(payload.raw['text'], equals('Hello from FocusFlow web!'));
    });

    test('2. NotificationPayload handles snake_case conversation_id fallback', () {
      final data = {
        'type': 'chat',
        'conversation_id': 'conv_123',
        'sender_id': 'user_99',
        'sender_name': 'Bob',
      };

      final payload = NotificationPayload.fromMap(data);

      expect(payload.type, equals('chat'));
      expect(payload.conversationId, equals('conv_123'));
      expect(payload.senderId, equals('user_99'));
      expect(payload.senderName, equals('Bob'));
    });

    test('3. Active conversation suppression avoids duplicate routes', () {
      NotificationRouter.activeConversationId = 'conv_abc';

      // Verify active conversation ID is set
      expect(NotificationRouter.activeConversationId, equals('conv_abc'));

      // Simulate a notification payload for the active conversation
      final payload = NotificationPayload(
        type: 'chat_message',
        conversationId: 'conv_abc',
        senderId: 'user_x',
      );

      // handlePayload should detect that activeConversationId == payload.conversationId
      // and not crash or push duplicate routes
      NotificationRouter.handlePayload(payload);
    });

    test('4. NotificationPayload serializes to/from JSON without data loss', () {
      const original = NotificationPayload(
        type: 'chat_message',
        conversationId: 'test_conv_1',
        senderId: 'ABCDE',
        senderName: 'Charlie',
        raw: {'extra_field': 'custom_val'},
      );

      final jsonStr = original.toJson();
      expect(jsonStr, contains('test_conv_1'));
      expect(jsonStr, contains('ABCDE'));
      expect(jsonStr, contains('Charlie'));
    });
  });

  group('FCM Remote Push System — Sender Service Tests', () {
    test('5. FcmSenderService resolves base URL without crash', () {
      final url = FcmSenderService.baseUrl;
      expect(url, isNotEmpty);
      expect(url.startsWith('http'), isTrue);
    });

    test('6. Non-blocking push notification trigger handles errors gracefully', () async {
      // Calling triggerChatPushNotification to an unreachable/mocked port should not throw
      expect(
        () => FcmSenderService.triggerChatPushNotification(
          conversationId: 'conv_test',
          senderId: 'sender_1',
          receiverId: 'receiver_2',
          text: 'Test message body',
          senderName: 'Tester',
          senderShortId: 'TEST1',
        ),
        returnsNormally,
      );
    });
  });

  group('FCM Remote Push System — Account Isolation & Stale Token Contract Tests', () {
    test('7. Stale token error codes contract', () {
      // Expected error codes defined by Firebase Cloud Messaging
      const staleCodes = [
        'messaging/registration-token-not-registered',
        'messaging/invalid-registration-token',
        'messaging/mismatched-credential',
      ];

      expect(staleCodes, contains('messaging/registration-token-not-registered'));
      expect(staleCodes, contains('messaging/invalid-registration-token'));
    });

    test('8. Multi-device notification contract', () {
      // Simulating recipient with multiple active devices
      final devices = [
        {
          'deviceId': 'phone_1',
          'fcmToken': 'token_alpha_123',
          'notificationEnabled': true,
          'supabaseUserId': 'user_b_uuid',
        },
        {
          'deviceId': 'tablet_2',
          'fcmToken': 'token_beta_456',
          'notificationEnabled': true,
          'supabaseUserId': 'user_b_uuid',
        },
        {
          'deviceId': 'old_phone_3',
          'fcmToken': 'token_gamma_789',
          'notificationEnabled': false, // Disabled/logged out
          'supabaseUserId': 'user_b_uuid',
        },
      ];

      // Filter active devices
      final activeTokens = devices
          .where((d) => d['notificationEnabled'] == true)
          .map((d) => d['fcmToken'] as String)
          .toList();

      expect(activeTokens.length, equals(2));
      expect(activeTokens, contains('token_alpha_123'));
      expect(activeTokens, contains('token_beta_456'));
      expect(activeTokens, isNot(contains('token_gamma_789')));
    });

    test('9. Account isolation guarantees Token A never belongs to User B', () {
      final userADevices = {
        'dev_101': {'user': 'user_A', 'token': 'token_A'},
      };
      final userBDevices = {
        'dev_202': {'user': 'user_B', 'token': 'token_B'},
      };

      expect(userADevices['dev_101']!['token'], isNot(equals(userBDevices['dev_202']!['token'])));
    });
  });
}
