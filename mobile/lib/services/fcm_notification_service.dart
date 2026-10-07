import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';
import 'notification_router.dart';
import 'notification_service.dart';

/// Top-level background message handler for Firebase Cloud Messaging.
///
/// Must be annotated with `@pragma('vm:entry-point')` so the Flutter engine can
/// invoke it in an isolated background isolate when the app is terminated or in background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await FirebaseService.initialize();
    }
    debugPrint('[FCM] Background message received: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM] Error in background message handler: $e');
  }
}

/// Centralized service managing Firebase Cloud Messaging (FCM).
///
/// Responsibilities:
/// 1. Initializes FCM and background messaging handlers.
/// 2. Requests and monitors notification permissions.
/// 3. Retrieves and registers FCM tokens per device under `users/{userId}/devices/{deviceId}`.
/// 4. Handles automatic token refreshes via [onTokenRefresh].
/// 5. Filters foreground messages (suppresses notifications when the relevant chat is active).
/// 6. Implements duplicate message protection.
/// 7. Cleans up / deactivates tokens on user logout to guarantee strict user isolation.
class FcmNotificationService {
  static final FcmNotificationService _instance =
      FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentDeviceId;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;

  /// Sliding cache of recently processed message IDs to prevent duplicate notifications.
  final List<String> _recentMessageIds = [];
  static const int _maxCachedIds = 150;

  // ─── Initialization ────────────────────────────────────────────────────────

  /// Initializes Firebase Cloud Messaging safely.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await FirebaseService.initialize();
      }

      // Configure top-level background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Configure foreground presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      _foregroundSubscription?.cancel();
      _foregroundSubscription =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for background notifications clicked to open app
      _messageOpenedAppSubscription?.cancel();
      _messageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen(_handleMessageOpenedApp);

      // Listen for automatic token refreshes
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);

      // Check if launched by tapping an FCM notification from terminated state
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM] App launched via terminated message: ${initialMessage.messageId}');
        NotificationRouter.handleRemoteMessage(initialMessage);
      }

      _isInitialized = true;
      debugPrint('[FCM] Firebase Messaging initialized successfully');
    } catch (e) {
      debugPrint('[FCM] Notice during initialization: $e');
    }
  }

  // ─── Permissions ───────────────────────────────────────────────────────────

  /// Requests notification permission from the OS.
  Future<bool> requestPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('[Notifications] Permission status: ${granted ? "authorized" : "denied"}');
      return granted;
    } catch (e) {
      debugPrint('[FCM] Permission request error: $e');
      return false;
    }
  }

  /// Silently checks current notification authorization status.
  Future<bool> areNotificationsPermitted() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  // ─── User Lifecycle & Token Management ─────────────────────────────────────

  /// Associates the active authenticated user with FCM.
  Future<void> onUserSignedIn(String userId) async {
    if (userId.isEmpty) return;

    if (_currentUserId != null && _currentUserId != userId) {
      await onUserSignedOut();
    }

    _currentUserId = userId;

    // Ensure Firebase Auth is bridge-authenticated for this Supabase user
    // so Firestore security rules permit device registration under users/{fbUid}/devices/{deviceId}
    await FirebaseService.ensureFirebaseAuth(userId);
    await syncDeviceToken();
  }

  /// Deactivates FCM state and clears device token association on logout.
  Future<void> onUserSignedOut() async {
    final outgoingUser = _currentUserId;
    final deviceId = _currentDeviceId ?? await _getOrCreateDeviceId();

    if (outgoingUser != null && outgoingUser.isNotEmpty) {
      try {
        final fbUid = FirebaseService.auth.currentUser?.uid ?? outgoingUser;
        final docRef = FirebaseService.firestore
            .collection('users')
            .doc(fbUid)
            .collection('devices')
            .doc(deviceId);

        await docRef.set({
          'notificationEnabled': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('[FCM] Deactivated device $deviceId for user $outgoingUser');
      } catch (e) {
        debugPrint('[FCM] Notice during device deactivation: $e');
      }
    }

    _currentUserId = null;
  }

  /// Registers or refreshes the current device token in Firestore under:
  /// `users/{userId}/devices/{deviceId}`
  Future<void> syncDeviceToken({bool? isEnabled}) async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    try {
      final token = await getFcmToken();
      if (token == null || token.isEmpty) return;

      final deviceId = await _getOrCreateDeviceId();
      _currentDeviceId = deviceId;

      final userPref = isEnabled ??
          await NotificationService()
              .getMessageNotificationPreference(userId);

      final annPref = await NotificationService()
          .getAnnouncementNotificationPreference(userId);

      // Ensure Firebase Auth is authenticated for this Supabase user
      final fbUid = await FirebaseService.ensureFirebaseAuth(userId) ??
          FirebaseService.auth.currentUser?.uid ??
          userId;

      final docRef = FirebaseService.firestore
          .collection('users')
          .doc(fbUid)
          .collection('devices')
          .doc(deviceId);

      bool exists = false;
      try {
        final snap = await docRef.get();
        exists = snap.exists;
      } catch (_) {}

      final data = <String, dynamic>{
        'fcmToken': token,
        'platform': defaultTargetPlatform.name,
        'deviceId': deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
        'appVersion': '1.0.0',
        'notificationEnabled': userPref,
        'announcementsEnabled': annPref,
        'supabaseUserId': userId,
      };

      if (!exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
      debugPrint('[FCM] Token registered for user $userId (device: $deviceId)');
    } catch (e) {
      debugPrint('[FCM] Error syncing device token: $e');
    }
  }

  /// Invoked when Firebase refreshes the registration token.
  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('[FCM] Token refreshed: $newToken');
    if (_currentUserId == null) return;
    await syncDeviceToken();
  }

  /// Retrieves the current FCM registration token.
  Future<String?> getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
      return null;
    }
  }

  // ─── Foreground & Tapping Handlers ─────────────────────────────────────────

  /// Handles incoming FCM message while FocusFlow is open in foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message received: ${message.messageId}');

    // Duplicate prevention
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      if (_recentMessageIds.contains(messageId)) {
        debugPrint('[FCM] Duplicate message ignored: $messageId');
        return;
      }
      _recentMessageIds.add(messageId);
      if (_recentMessageIds.length > _maxCachedIds) {
        _recentMessageIds.removeAt(0);
      }
    }

    final data = message.data;
    final convId = (data['conversationId'] ?? data['conversation_id']) as String?;

    // Check if the user is currently viewing this exact conversation
    if (convId != null &&
        NotificationRouter.activeConversationId != null &&
        NotificationRouter.activeConversationId == convId) {
      debugPrint('[FCM] User is actively in conversation $convId — skipping notification banner');
      return;
    }

    // Check user preference
    final type = (data['type'] as String?)?.toLowerCase() ?? 'chat_message';
    final userId = _currentUserId ?? '';
    if (type == 'chat_message' || type == 'chat' || type == 'message') {
      final enabled = await NotificationService()
          .getMessageNotificationPreference(userId);
      if (!enabled) {
        debugPrint('[FCM] Chat notifications are disabled in user settings');
        return;
      }
    } else if (type == 'announcement') {
      final enabled = await NotificationService()
          .getAnnouncementNotificationPreference(userId);
      if (!enabled) {
        debugPrint('[FCM] Announcement notifications are disabled in user settings');
        return;
      }
    }

    // Show stylish local notification banner
    final title = message.notification?.title ??
        data['title'] ??
        data['senderName'] ??
        'FocusFlow Message';
    final body = message.notification?.body ??
        data['body'] ??
        data['text'] ??
        'New message received';

    await NotificationService().showMessageNotification(
      id: messageId.hashCode,
      title: title,
      body: body,
      payload: Map<String, dynamic>.from(data),
    );
  }

  /// Handles notification tap when opening app from background.
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped (opened app)');
    NotificationRouter.handleRemoteMessage(message);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Generates or retrieves a persistent, unique device identifier.
  Future<String> _getOrCreateDeviceId() async {
    if (_currentDeviceId != null) return _currentDeviceId!;

    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'focusflow_device_unique_id';
      String? deviceId = prefs.getString(key);
      if (deviceId == null || deviceId.isEmpty) {
        final rand = Random().nextInt(999999);
        deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
        await prefs.setString(key, deviceId);
      }
      _currentDeviceId = deviceId;
      return deviceId;
    } catch (_) {
      final fallback = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      _currentDeviceId = fallback;
      return fallback;
    }
  }

  /// Cancels listeners and releases resources.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();
    _isInitialized = false;
  }
}
