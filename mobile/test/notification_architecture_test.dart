import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/models/learning_session.dart';
import 'package:focus_flow/services/notification_router.dart';
import 'package:focus_flow/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationService — Local Smart Reminders & Preferences', () {
    test('Default preference returns fallback when not explicitly stored', () async {
      final service = NotificationService();
      final pref = await service.getPreference('user_123', fallback: false);
      expect(pref, isFalse);

      final prefTrue = await service.getPreference('user_123', fallback: true);
      expect(prefTrue, isTrue);
    });

    test('Stored preference is persisted and isolated per user ID', () async {
      final service = NotificationService();
      await service.setPreference('user_A', true);
      await service.setPreference('user_B', false);

      expect(await service.getPreference('user_A'), isTrue);
      expect(await service.getPreference('user_B'), isFalse);
      expect(await service.getStoredPreference('user_C'), isNull);
    });

    test('Remote message and announcement preferences are isolated per user', () async {
      final service = NotificationService();
      expect(await service.getMessageNotificationPreference('user_A'), isTrue);

      await service.setMessageNotificationPreference('user_A', false);
      expect(await service.getMessageNotificationPreference('user_A'), isFalse);
      expect(await service.getMessageNotificationPreference('user_B'), isTrue);

      await service.setAnnouncementNotificationPreference('user_B', false);
      expect(await service.getAnnouncementNotificationPreference('user_A'), isTrue);
      expect(await service.getAnnouncementNotificationPreference('user_B'), isFalse);
    });

    test('cancelAllReminders completes without error in test environment', () async {
      final service = NotificationService();
      await expectLater(service.cancelAllReminders(), completes);
    });

    test('sendTestLocalNotification completes without error', () async {
      final service = NotificationService();
      await expectLater(service.sendTestLocalNotification(), completes);
    });

    test('updateDailyReminders handles planned sessions without crashing', () async {
      final service = NotificationService();
      final now = DateTime.now();
      final sessions = [
        LearningSession(
          id: 's1',
          userId: 'user_A',
          skillId: 'sk1',
          skillName: 'DSA',
          scheduledDate: now.toIso8601String().split('T')[0],
          status: 'planned',
          durationMinutes: 45,
          plannedDuration: 45,
          createdAt: now,
        ),
        LearningSession(
          id: 's2',
          userId: 'user_A',
          skillId: 'sk2',
          skillName: 'Flutter',
          scheduledDate: now.toIso8601String().split('T')[0],
          status: 'completed',
          durationMinutes: 60,
          plannedDuration: 60,
          createdAt: now,
        ),
      ];

      await expectLater(
        service.updateDailyReminders('user_A', sessions, true),
        completes,
      );
    });
  });

  group('NotificationRouter — Payload Routing & Suppression', () {
    test('NotificationPayload parses structured map correctly', () {
      final map = {
        'type': 'chat_message',
        'conversationId': 'conv_123',
        'senderId': 'user_X',
        'senderName': 'Alice',
      };
      final payload = NotificationPayload.fromMap(map);

      expect(payload.type, 'chat_message');
      expect(payload.conversationId, 'conv_123');
      expect(payload.senderId, 'user_X');
      expect(payload.senderName, 'Alice');
    });

    test('NotificationPayload serializes and deserializes json', () {
      final payload = NotificationPayload(
        type: 'announcement',
        announcementId: 'ann_456',
      );
      final jsonStr = payload.toJson();
      final decoded = jsonDecode(jsonStr);
      final parsed = NotificationPayload.fromMap(decoded);

      expect(parsed.type, 'announcement');
      expect(parsed.announcementId, 'ann_456');
    });

    test('activeConversationId is tracked and clears cleanly', () {
      NotificationRouter.activeConversationId = 'conv_999';
      expect(NotificationRouter.activeConversationId, 'conv_999');

      NotificationRouter.activeConversationId = null;
      expect(NotificationRouter.activeConversationId, isNull);
    });

    test('handlePayload queues when router is not yet registered', () {
      // Should not throw or crash even when router is null
      expect(
        () => NotificationRouter.handle({
          'type': 'chat_message',
          'conversationId': 'conv_test',
        }),
        returnsNormally,
      );
    });
  });
}
