import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/learning_session.dart';
import 'notification_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const String _prefPrefix = 'focusflow_practice_reminders_';
  static const String _msgPrefPrefix = 'focusflow_msg_reminders_';
  static const String _annPrefPrefix = 'focusflow_ann_reminders_';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Deterministic IDs for personal skill reminder slots
  static const int _daytimeNotificationId = 84001;
  static const int _eveningNotificationId = 84002;

  final List<String> _motivationalPhrases = [
    'is still waiting for you',
    'is planned for today',
    'needs your attention',
    'is on your schedule today',
    'is calling your name',
  ];

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          NotificationRouter.handleNotificationResponse(response);
        },
      );

      // Create Android Notification Channels
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        // Channel 1: Local skill reminders
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'focusflow_reminders',
            'Daily Reminders',
            description:
                'Smart reminders to complete your daily planned skills',
            importance: Importance.high,
          ),
        );

        // Channel 2: FCM / chat messages
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'focusflow_messages',
            'Messages & Chat',
            description:
                'Notifications for 1-to-1 direct messages and chats',
            importance: Importance.high,
          ),
        );
      }

      // Check if launched by notification tap from terminated state
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        if (launchDetails?.notificationResponse != null) {
          NotificationRouter.handleNotificationResponse(
              launchDetails!.notificationResponse);
        }
      }
    } catch (e) {
      debugPrint('[Notifications] Initialization notice: $e');
    }

    _isInitialized = true;
  }

  // ─── Preference persistence (SharedPreferences, per-user key) ──────────────

  /// Returns null if the user has never explicitly set practice reminder preference.
  Future<bool?> getStoredPreference(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$userId';
      if (prefs.containsKey(key)) return prefs.getBool(key);
    } catch (_) {}
    return null;
  }

  /// Returns the stored preference, or [fallback] if not yet set.
  Future<bool> getPreference(String userId, {bool fallback = false}) async {
    final stored = await getStoredPreference(userId);
    return stored ?? fallback;
  }

  /// Persists practice reminder preference for [userId].
  Future<void> setPreference(String userId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefPrefix$userId', enabled);
    } catch (_) {}
  }

  /// Returns message notifications preference (default true).
  Future<bool> getMessageNotificationPreference(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_msgPrefPrefix$userId';
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Persists message notifications preference for [userId].
  Future<void> setMessageNotificationPreference(
      String userId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_msgPrefPrefix$userId', enabled);
    } catch (_) {}
  }

  /// Returns announcement notifications preference (default true).
  Future<bool> getAnnouncementNotificationPreference(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_annPrefPrefix$userId';
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Persists announcement notifications preference for [userId].
  Future<void> setAnnouncementNotificationPreference(
      String userId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_annPrefPrefix$userId', enabled);
    } catch (_) {}
  }

  // ─── OS Permission ─────────────────────────────────────────────────────────

  /// Requests OS notification permission. Shows the native dialog on Android
  /// 13+ and iOS. Returns true when permission is granted.
  Future<bool> requestPermissions() async {
    try {
      bool? granted;

      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        granted = await androidImpl.requestNotificationsPermission();
        granted ??= await androidImpl.areNotificationsEnabled();
      }

      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final result = granted ?? false;
      debugPrint('[Notifications] Permission status: ${result ? "authorized" : "denied"}');
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Silently checks whether OS notification permission is currently granted.
  /// Never triggers a permission prompt.
  Future<bool> areNotificationsPermitted() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? false;
      }

      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final status = await iosImpl.checkPermissions();
        return status?.isEnabled ?? false;
      }

      final macosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      if (macosImpl != null) {
        final status = await macosImpl.checkPermissions();
        return status?.isEnabled ?? false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Scheduling (Local Smart Reminders) ───────────────────────────────────

  /// Cancels both pending reminder slots. Safe to call even when uninitialized.
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancel(id: _daytimeNotificationId);
      await _notificationsPlugin.cancel(id: _eveningNotificationId);
      debugPrint('[Notifications] Local reminders cancelled');
    } catch (_) {}
  }

  /// Called whenever sessions or user preference change.
  /// Cancels stale schedules, then reschedules if reminders are enabled and
  /// the OS permission is granted.
  Future<void> updateDailyReminders(
    String userId,
    List<LearningSession> todaySessions,
    bool isEnabled,
  ) async {
    try {
      // Step 1: Always cancel existing schedules to avoid duplicates.
      await cancelAllReminders();

      if (!isEnabled) return;

      // Step 2: Guard — OS permission may have been revoked.
      final permitted = await areNotificationsPermitted();
      if (!permitted) return;

      // Step 3: Only remind about incomplete tasks.
      final incompleteSessions = todaySessions
          .where((s) => s.status == 'planned')
          .toList();

      if (incompleteSessions.isEmpty) return; // All tasks complete for today.

      // Step 4: Build notification body with smart grouping.
      final taskNames =
          incompleteSessions.map((s) => s.skillName ?? 'Skill').toList();

      final String tasksString;
      if (taskNames.length == 1) {
        tasksString = taskNames.first;
      } else if (taskNames.length == 2) {
        tasksString = '${taskNames[0]} and ${taskNames[1]}';
      } else {
        tasksString =
            '${taskNames[0]}, ${taskNames[1]}, and ${taskNames.length - 2} more';
      }

      // Step 5: Compute deterministic-but-randomised schedule times.
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final daySeed = '$userId${todayStr}day'.hashCode;
      final eveningSeed = '$userId${todayStr}evening'.hashCode;

      final dayOffsetMins = Random(daySeed).nextInt(240); // 11 AM – 3 PM
      final eveningOffsetMins =
          Random(eveningSeed).nextInt(210); // 6 PM – 9:30 PM

      final now = DateTime.now();
      final dayTime = DateTime(now.year, now.month, now.day, 11, 0, 0)
          .add(Duration(minutes: dayOffsetMins));
      final eveningTime = DateTime(now.year, now.month, now.day, 18, 0, 0)
          .add(Duration(minutes: eveningOffsetMins));

      final phraseIndex = daySeed.abs() % _motivationalPhrases.length;
      final body = '🔥 $tasksString ${_motivationalPhrases[phraseIndex]}.';

      const androidDetails = AndroidNotificationDetails(
        'focusflow_reminders',
        'Daily Reminders',
        channelDescription:
            'Smart reminders to complete your daily planned skills',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({'type': 'reminder'});

      // Step 6: Schedule only future slots.
      if (dayTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          id: _daytimeNotificationId,
          title: 'Time to Focus!',
          body: body,
          scheduledDate: tz.TZDateTime.from(dayTime, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }

      if (eveningTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          id: _eveningNotificationId,
          title: 'End the day strong!',
          body: body,
          scheduledDate: tz.TZDateTime.from(eveningTime, tz.local),
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      }

      debugPrint('[Notifications] Local reminders scheduled for $userId');
    } catch (_) {
      // Silently ignore scheduling failures (e.g. in test environment)
    }
  }

  // ─── Foreground & Remote Message Display ──────────────────────────────────

  /// Shows an instant local notification for an incoming chat message.
  Future<void> showMessageNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'focusflow_messages',
        'Messages & Chat',
        channelDescription:
            'Notifications for 1-to-1 direct messages and chats',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('[Notifications] Error displaying message notification: $e');
    }
  }

  // ─── Test & Debug Helpers (Dev-only) ──────────────────────────────────────

  /// Dispatches an immediate test local reminder for validation.
  Future<void> sendTestLocalNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'focusflow_reminders',
        'Daily Reminders',
        channelDescription:
            'Smart reminders to complete your daily planned skills',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: 99999,
        title: 'Time to Focus! (Test)',
        body: '🔥 DSA is still waiting for you. Complete it before the day ends.',
        notificationDetails: platformDetails,
        payload: jsonEncode({'type': 'reminder'}),
      );
      debugPrint('[Notifications] Test local notification sent');
    } catch (e) {
      debugPrint('[Notifications] Error sending test notification: $e');
    }
  }
}
