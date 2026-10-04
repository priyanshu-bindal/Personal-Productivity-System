import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

/// Client-side service to trigger server-side FCM push notifications.
///
/// Ensures:
/// 1. App A never handles Firebase Admin SDK or service accounts directly.
/// 2. Dispatches HTTP POST to the centralized Next.js backend `/api/notify/chat-message`.
/// 3. Completely non-blocking (fire-and-forget) so message sending never fails due to network or FCM errors.
class FcmSenderService {
  /// Returns the appropriate API base URL based on platform and environment.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return AppConstants.apiBaseUrl;
  }

  /// Triggers a remote push notification for a chat message via the server.
  static Future<void> triggerChatPushNotification({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    String? senderShortId,
  }) async {
    // Run asynchronously without awaiting to ensure instant UI response
    _sendAsync(
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      senderName: senderName,
      senderShortId: senderShortId,
    );
  }

  static Future<void> _sendAsync({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    String? senderShortId,
  }) async {
    final endpoint = '$baseUrl/api/notify/chat-message';
    debugPrint('[FCM] Dispatching notification request to server for recipient: $receiverId');

    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);

      final uri = Uri.parse(endpoint);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final payload = jsonEncode({
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        if (senderName != null && senderName.isNotEmpty) 'senderName': senderName,
        if (senderShortId != null && senderShortId.isNotEmpty) 'senderShortId': senderShortId,
      });

      request.write(payload);
      final response = await request.close();

      if (response.statusCode == 200) {
        debugPrint('[FCM] Server push notification request accepted (HTTP 200)');
      } else {
        debugPrint('[FCM] Notice: Server notification endpoint returned HTTP ${response.statusCode}');
      }
    } catch (e) {
      // Non-blocking: Server offline or unreachable should never crash the Flutter client
      debugPrint('[FCM] Notice dispatching chat push notification to server: $e');
    } finally {
      client?.close(force: true);
    }
  }
}
