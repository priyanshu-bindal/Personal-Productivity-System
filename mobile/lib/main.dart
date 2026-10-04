import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/supabase_service.dart';
import 'services/firebase_service.dart';
import 'services/user_session_manager.dart';
import 'services/notification_service.dart';
import 'services/fcm_notification_service.dart';
import 'services/notification_router.dart';
import 'providers/sessions_provider.dart';
import 'providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce portrait orientation & dark status bar overlay
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase SDK
  await SupabaseService.initialize();

  // Initialize Firebase SDK (for chat system)
  await FirebaseService.initialize();

  // Initialize Local Notification Service (for offline personal smart reminders)
  await NotificationService().initialize();

  // Initialize Firebase Cloud Messaging Service (for remote 1-to-1 chat & announcements)
  await FcmNotificationService().initialize();

  // If user is already authenticated on launch, bind FCM
  final initialUser = SupabaseService.currentUserId;
  if (initialUser != null && initialUser.isNotEmpty) {
    FcmNotificationService().onUserSignedIn(initialUser);
  }

  runApp(
    const ProviderScope(
      child: FocusFlowApp(),
    ),
  );
}

class FocusFlowApp extends ConsumerWidget {
  const FocusFlowApp({super.key});

  Future<void> _syncNotifications(WidgetRef ref) async {
    // Always read userId fresh from the auth singleton — never use a captured
    // or cached value, so we cannot schedule for a stale/wrong user.
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      // No authenticated user — cancel any leftover notifications defensively.
      await NotificationService().cancelAllReminders();
      return;
    }

    final profileAsync = ref.read(profileProvider);
    final profilePref = profileAsync.valueOrNull?.practiceReminders;
    final isEnabled = await NotificationService().getPreference(
      userId,
      fallback: profilePref ?? false,
    );

    if (!isEnabled) {
      await NotificationService().cancelAllReminders();
      return;
    }

    final sessionsAsync = ref.read(sessionsProvider);
    if (sessionsAsync.hasValue && sessionsAsync.value != null) {
      final sessions = sessionsAsync.value!;

      // Guard: if any session belongs to a different user than the currently
      // authenticated one, the Riverpod cache is stale (account switch in
      // progress). Bail out — the UserSessionManager will invalidate providers
      // and a fresh sync will fire once new data arrives.
      if (sessions.isNotEmpty && sessions.first.userId != userId) return;

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final todaySessions =
          sessions.where((s) => s.scheduledDate == todayStr).toList();

      await NotificationService().updateDailyReminders(userId, todaySessions, true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep user session manager active throughout the app lifecycle
    ref.watch(userSessionManagerProvider);
    final router = ref.watch(routerProvider);
    NotificationRouter.setRouter(router);

    // Initial sync on app launch / rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNotifications(ref);
    });

    // Sync notifications when sessions or profile updates
    ref.listen(sessionsProvider, (previous, next) {
      _syncNotifications(ref);
    });
    ref.listen(profileProvider, (previous, next) {
      _syncNotifications(ref);
    });

    return MaterialApp.router(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
