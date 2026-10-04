import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Structured payload model for both local and remote notifications.
class NotificationPayload {
  final String type; // 'chat_message', 'announcement', 'reminder', etc.
  final String? conversationId;
  final String? senderId;
  final String? senderName;
  final String? announcementId;
  final Map<String, dynamic> raw;

  const NotificationPayload({
    required this.type,
    this.conversationId,
    this.senderId,
    this.senderName,
    this.announcementId,
    this.raw = const {},
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    return NotificationPayload(
      type: (data['type'] as String?)?.toLowerCase() ?? 'unknown',
      conversationId:
          (data['conversationId'] ?? data['conversation_id']) as String?,
      senderId: (data['senderId'] ?? data['sender_id']) as String?,
      senderName: (data['senderName'] ?? data['sender_name']) as String?,
      announcementId:
          (data['announcementId'] ?? data['announcement_id']) as String?,
      raw: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (conversationId != null) 'conversationId': conversationId,
      if (senderId != null) 'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (announcementId != null) 'announcementId': announcementId,
      ...raw,
    };
  }

  String toJson() => jsonEncode(toMap());
}

/// Centralized notification router.
///
/// Decouples Firebase and local notification callbacks from screen navigation.
/// Supports delayed routing if the router is not yet initialized during app startup.
class NotificationRouter {
  static GoRouter? _router;
  static NotificationPayload? _pendingPayload;

  /// Tracks the ID of the currently open chat conversation to suppress duplicate notifications.
  static String? activeConversationId;

  /// Associates the active [GoRouter] instance with the router.
  static void setRouter(GoRouter router) {
    _router = router;
    if (_pendingPayload != null) {
      final payload = _pendingPayload!;
      _pendingPayload = null;
      debugPrint('[Notifications] Dispatching queued notification payload: ${payload.type}');
      handlePayload(payload);
    }
  }

  /// Handles incoming [NotificationResponse] from `flutter_local_notifications`.
  static void handleNotificationResponse(NotificationResponse? response) {
    if (response == null) return;
    debugPrint('[Notifications] Notification tapped (local)');
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) {
      // Default tap with no payload navigates to today
      handlePayload(const NotificationPayload(type: 'reminder'));
      return;
    }

    try {
      final decoded = jsonDecode(payloadStr);
      if (decoded is Map<String, dynamic>) {
        handle(decoded);
      } else {
        handlePayload(const NotificationPayload(type: 'reminder'));
      }
    } catch (_) {
      handlePayload(const NotificationPayload(type: 'reminder'));
    }
  }

  /// Handles tap on a remote FCM [RemoteMessage].
  static void handleRemoteMessage(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification != null) {
      data['title'] ??= message.notification!.title;
      data['body'] ??= message.notification!.body;
    }
    handle(data);
  }

  /// Parses arbitrary raw data into a [NotificationPayload] and routes it.
  static void handle(Map<String, dynamic> data) {
    final payload = NotificationPayload.fromMap(data);
    handlePayload(payload);
  }

  /// Direct routing based on structured payload type.
  static void handlePayload(NotificationPayload payload) {
    if (_router == null) {
      _pendingPayload = payload;
      debugPrint('[Notifications] Router not ready yet; payload queued (${payload.type})');
      return;
    }

    debugPrint('[Notifications] Routing notification payload of type: ${payload.type}');

    switch (payload.type) {
      case 'chat_message':
      case 'chat':
      case 'message':
        final convId = payload.conversationId;
        if (convId != null && convId.isNotEmpty) {
          if (activeConversationId == convId) {
            debugPrint('[Notifications] Already in conversation $convId — skipping duplicate route navigation');
            return;
          }
          _router!.push(
            '/messages/chat/$convId',
            extra: {
              'otherChatId': payload.senderId,
              'otherDisplayName': payload.senderName,
            },
          );
        } else {
          _router!.push('/messages');
        }
        break;

      case 'announcement':
        _router!.push('/messages');
        break;

      case 'reminder':
      case 'daily_reminder':
      case 'task':
      case 'skill':
        _router!.go('/today');
        break;

      default:
        if (payload.conversationId != null && payload.conversationId!.isNotEmpty) {
          _router!.push('/messages/chat/${payload.conversationId}');
        } else {
          _router!.go('/today');
        }
        break;
    }
  }
}
