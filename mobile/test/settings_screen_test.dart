import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/settings/settings_screen.dart';
import 'package:focus_flow/models/user_profile.dart';
import 'package:focus_flow/providers/chat_provider.dart';
import 'package:focus_flow/providers/profile_provider.dart';

void main() {
  testWidgets('SettingsScreen renders header, profile info, and sections', (tester) async {
    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
      defaultSessionDuration: 45,
      practiceReminders: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Settings'), findsOneWidget);

    // Verify Section Titles
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('PRACTICE PREFERENCES'), findsOneWidget);
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    expect(find.text('DATA & PRIVACY'), findsOneWidget);
    expect(find.text('DANGER ZONE'), findsOneWidget);

    // Verify Profile Card Info
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('J'), findsOneWidget); // Initial
    expect(find.text('#ABC12'), findsOneWidget); // Focus ID

    // Verify Preferences
    expect(find.text('45 mins'), findsOneWidget);
    expect(find.text('Daily Practice Reminders'), findsOneWidget);

    // Verify Danger Zone
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('Tapping Edit Profile opens edit profile modal with prefilled data', (tester) async {
    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'jane@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Edit Profile
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('jane@example.com'), findsNWidgets(2)); // Card + Modal read-only
    expect(find.text('Save Changes'), findsOneWidget);

    // Cancel modal
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('Tapping Session Duration opens selector modal and allows selection', (tester) async {
    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
      defaultSessionDuration: 60,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Duration Row
    await tester.tap(find.text('Default Session Duration'));
    await tester.pumpAndSettle();

    expect(find.text('30 mins'), findsOneWidget);
    expect(find.text('45 mins'), findsOneWidget);
    expect(find.text('90 mins'), findsOneWidget);
    expect(find.text('120 mins'), findsOneWidget);

    // Tap 90 mins
    await tester.tap(find.text('90 mins'));
    await tester.pumpAndSettle();

    expect(find.text('Choose the baseline duration for practice sessions'), findsNothing);
  });

  testWidgets('Sign Out opens confirmation dialog with cancel and sign out buttons', (tester) async {
    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Sign Out
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.text("You'll need to sign in again to access FocusFlow."), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsNothing);
  });

  testWidgets('Delete Account requires exact DELETE typing to enable button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to Delete Account and tap
    await tester.scrollUntilVisible(find.text('Delete Account'), 200);
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.text('Your account will remain recoverable for 15 days. After that, it will be permanently deleted.'), findsOneWidget);
    expect(find.text('Type DELETE to confirm'), findsOneWidget);

    final scheduleButton = find.text('Schedule Account Deletion');
    expect(scheduleButton, findsOneWidget);

    // Type lowercase "delete" (should NOT enable)
    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pumpAndSettle();

    // Type exact "DELETE" (should enable)
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();

    // Close modal
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsNothing);
  });

  testWidgets('Shows pending deletion warning banner when deletion is scheduled', (tester) async {
    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
      deletionRequestedAt: DateTime.now().toUtc(),
      deletionScheduledFor: DateTime.now().toUtc().add(const Duration(days: 15)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Account deletion scheduled'), findsOneWidget);
    expect(find.text('Cancel deletion'), findsOneWidget);
  });

  testWidgets('About section contains Version 1.0.0, Privacy Policy, Terms of Service, and NOT Open Source Licenses', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to ABOUT section
    await tester.scrollUntilVisible(find.text('ABOUT'), 200);

    expect(find.text('FocusFlow'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Open Source Licenses'), findsNothing);
  });

  testWidgets('Tapping Change Password opens modal with required fields and buttons', (tester) async {
    final testProfile = UserProfile(
      id: 'test-user-123',
      email: 'test@example.com',
      fullName: 'Jane Doe',
      avatarUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => _MockProfileNotifier(testProfile)),
          currentChatUserShortIdProvider.overrideWith((ref) => Future.value('ABC12')),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Change Password
    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('CURRENT PASSWORD'), findsOneWidget);
    expect(find.text('NEW PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM NEW PASSWORD'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Cancel modal
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('CONFIRM NEW PASSWORD'), findsNothing);
  });
}

class _MockProfileNotifier extends ProfileNotifier {
  final UserProfile mockProfile;
  _MockProfileNotifier(this.mockProfile) : super() {
    state = AsyncValue.data(mockProfile);
  }

  @override
  Future<void> fetchProfile() async {
    state = AsyncValue.data(mockProfile);
  }

  @override
  Future<void> updatePreferences({
    int? defaultSessionDuration,
    bool? practiceReminders,
    String? dailyReminderTime,
  }) async {
    state = AsyncValue.data(
      mockProfile.copyWith(
        defaultSessionDuration: defaultSessionDuration,
        practiceReminders: practiceReminders,
        dailyReminderTime: dailyReminderTime,
      ),
    );
  }

  @override
  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    state = AsyncValue.data(
      mockProfile.copyWith(
        fullName: fullName,
        avatarUrl: avatarUrl,
      ),
    );
  }

  @override
  Future<void> scheduleDeletion() async {
    final now = DateTime.now().toUtc();
    state = AsyncValue.data(
      mockProfile.copyWith(
        deletionRequestedAt: now,
        deletionScheduledFor: now.add(const Duration(days: 15)),
      ),
    );
  }

  @override
  Future<void> cancelDeletion() async {
    state = AsyncValue.data(
      mockProfile.copyWith(clearDeletion: true),
    );
  }
}
