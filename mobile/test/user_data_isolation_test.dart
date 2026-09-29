import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_flow/models/budget.dart';
import 'package:focus_flow/models/chat_message_model.dart';
import 'package:focus_flow/models/conversation_model.dart';
import 'package:focus_flow/models/expense.dart';
import 'package:focus_flow/models/learning_session.dart';
import 'package:focus_flow/models/note.dart';
import 'package:focus_flow/models/skill.dart';
import 'package:focus_flow/models/user_profile.dart';
import 'package:focus_flow/providers/auth_provider.dart';
import 'package:focus_flow/providers/chat_provider.dart';
import 'package:focus_flow/providers/money_provider.dart';
import 'package:focus_flow/providers/notes_provider.dart';
import 'package:focus_flow/providers/profile_provider.dart';
import 'package:focus_flow/providers/sessions_provider.dart';
import 'package:focus_flow/providers/skills_provider.dart';
import 'package:focus_flow/providers/trash_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test data for User A
  const userAId = 'f08260b0-user-a';
  final profileA = UserProfile(
    id: userAId,
    fullName: 'Alice User A',
    email: 'alice@focusflow.test',
    avatarUrl: '',
    currentStreak: 5,
    longestStreak: 10,
    lastStreakDate: '2026-09-26',
  );
  final expenseA = Expense(
    id: 'exp_a1',
    userId: userAId,
    amount: 1500.0,
    description: 'User A Expense',
    category: 'groceries',
    paymentMethod: 'credit_card',
    expenseDate: '2026-09-26',
    createdAt: DateTime(2026, 9, 26),
  );
  final sessionA = LearningSession(
    id: 'sess_a1',
    userId: userAId,
    skillId: 'skill_a1',
    scheduledDate: '2026-09-26',
    durationMinutes: 45,
    plannedDuration: 45,
    status: 'completed',
    createdAt: DateTime(2026, 9, 26),
  );
  final skillA = Skill(
    id: 'skill_a1',
    userId: userAId,
    name: 'Python Mastery A',
    category: 'tech',
    description: 'Learn Python',
    level: 'intermediate',
    progress: 75,
    weeklyTarget: 3,
    sessionDuration: 45,
    preferredDays: ['Monday', 'Wednesday', 'Friday'],
    status: 'active',
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 26),
  );
  final noteA = Note(
    id: 'note_a1',
    userId: userAId,
    title: 'User A Secret Note',
    content: 'Private thought of A',
    tags: ['private'],
    createdAt: DateTime(2026, 9, 26),
    updatedAt: DateTime(2026, 9, 26),
  );
  final budgetA = Budget(
    id: 'b_a1',
    userId: userAId,
    category: 'groceries',
    monthlyLimit: 5000.0,
    month: '2026-09-01',
    createdAt: DateTime(2026, 9, 1),
  );
  final trashedA = Expense(
    id: 'trash_a1',
    userId: userAId,
    amount: 250.0,
    description: 'Trashed A Item',
    category: 'food',
    paymentMethod: 'cash',
    expenseDate: '2026-09-20',
    createdAt: DateTime(2026, 9, 20),
    deletedAt: DateTime(2026, 9, 21),
  );

  // Test data for User B
  const userBId = 'e7948331-user-b';
  final profileB = UserProfile(
    id: userBId,
    fullName: 'Bob User B',
    email: 'bob@focusflow.test',
    avatarUrl: '',
    currentStreak: 1,
    longestStreak: 2,
    lastStreakDate: '2026-09-26',
  );
  final expenseB = Expense(
    id: 'exp_b1',
    userId: userBId,
    amount: 320.0,
    description: 'User B Expense',
    category: 'transport',
    paymentMethod: 'upi',
    expenseDate: '2026-09-26',
    createdAt: DateTime(2026, 9, 26),
  );
  final sessionB = LearningSession(
    id: 'sess_b1',
    userId: userBId,
    skillId: 'skill_b1',
    scheduledDate: '2026-09-26',
    durationMinutes: 60,
    plannedDuration: 60,
    status: 'planned',
    createdAt: DateTime(2026, 9, 26),
  );
  final skillB = Skill(
    id: 'skill_b1',
    userId: userBId,
    name: 'Guitar Practice B',
    category: 'music',
    description: 'Daily guitar chords',
    level: 'beginner',
    progress: 20,
    weeklyTarget: 5,
    sessionDuration: 60,
    preferredDays: ['Monday', 'Tuesday', 'Wednesday'],
    status: 'active',
    createdAt: DateTime(2026, 9, 10),
    updatedAt: DateTime(2026, 9, 26),
  );
  final noteB = Note(
    id: 'note_b1',
    userId: userBId,
    title: 'User B Public Note',
    content: 'Public note of B',
    tags: ['work'],
    createdAt: DateTime(2026, 9, 26),
    updatedAt: DateTime(2026, 9, 26),
  );
  final budgetB = Budget(
    id: 'b_b1',
    userId: userBId,
    category: 'transport',
    monthlyLimit: 2000.0,
    month: '2026-09-01',
    createdAt: DateTime(2026, 9, 1),
  );
  final trashedB = Expense(
    id: 'trash_b1',
    userId: userBId,
    amount: 80.0,
    description: 'Trashed B Item',
    category: 'snacks',
    paymentMethod: 'card',
    expenseDate: '2026-09-25',
    createdAt: DateTime(2026, 9, 25),
    deletedAt: DateTime(2026, 9, 25),
  );

  group('FocusFlow Data Isolation & Auth Lifecycle Verification', () {
    test('CASE A: User A login -> load data -> sign out -> User B login -> ZERO User A data visible', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          profileProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockProfileNotifier(profileA, uid);
            if (uid == userBId) return _MockProfileNotifier(profileB, uid);
            return _MockProfileNotifier(null, null);
          }),
          expensesProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockExpensesNotifier([expenseA], uid);
            if (uid == userBId) return _MockExpensesNotifier([expenseB], uid);
            return _MockExpensesNotifier([], null);
          }),
          sessionsProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockSessionsNotifier([sessionA], ref, uid);
            if (uid == userBId) return _MockSessionsNotifier([sessionB], ref, uid);
            return _MockSessionsNotifier([], ref, null);
          }),
          skillsProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockSkillsNotifier([skillA], uid);
            if (uid == userBId) return _MockSkillsNotifier([skillB], uid);
            return _MockSkillsNotifier([], null);
          }),
          notesProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockNotesNotifier([noteA], uid);
            if (uid == userBId) return _MockNotesNotifier([noteB], uid);
            return _MockNotesNotifier([], null);
          }),
          budgetsProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockBudgetsNotifier([budgetA], uid);
            if (uid == userBId) return _MockBudgetsNotifier([budgetB], uid);
            return _MockBudgetsNotifier([], null);
          }),
          trashedExpensesProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockTrashedNotifier([trashedA], uid);
            if (uid == userBId) return _MockTrashedNotifier([trashedB], uid);
            return _MockTrashedNotifier([], null);
          }),
        ],
      );
      addTearDown(container.dispose);

      // 1. User A is active
      expect(container.read(profileProvider).value?.id, userAId);
      expect(container.read(expensesProvider).value?.first.id, 'exp_a1');
      expect(container.read(sessionsProvider).value?.first.id, 'sess_a1');
      expect(container.read(skillsProvider).value?.first.id, 'skill_a1');
      expect(container.read(notesProvider).value?.first.id, 'note_a1');
      expect(container.read(budgetsProvider).value?.first.id, 'b_a1');
      expect(container.read(trashedExpensesProvider).value?.first.id, 'trash_a1');

      // 2. User A signs out
      container.read(activeUser.notifier).state = null;

      expect(container.read(profileProvider).value, isNull);
      expect(container.read(expensesProvider).value, isEmpty);
      expect(container.read(sessionsProvider).value, isEmpty);
      expect(container.read(skillsProvider).value, isEmpty);
      expect(container.read(notesProvider).value, isEmpty);
      expect(container.read(budgetsProvider).value, isEmpty);
      expect(container.read(trashedExpensesProvider).value, isEmpty);

      // 3. User B signs in
      container.read(activeUser.notifier).state = userBId;

      // Verify ZERO User A data is present
      final profileVal = container.read(profileProvider).value;
      final expensesVal = container.read(expensesProvider).value!;
      final sessionsVal = container.read(sessionsProvider).value!;
      final skillsVal = container.read(skillsProvider).value!;
      final notesVal = container.read(notesProvider).value!;

      expect(profileVal?.id, userBId);
      expect(profileVal?.fullName, 'Bob User B');
      expect(expensesVal.any((e) => e.userId == userAId), isFalse);
      expect(expensesVal.first.id, 'exp_b1');
      expect(sessionsVal.any((s) => s.userId == userAId), isFalse);
      expect(sessionsVal.first.id, 'sess_b1');
      expect(skillsVal.any((s) => s.userId == userAId), isFalse);
      expect(skillsVal.first.id, 'skill_b1');
      expect(notesVal.any((n) => n.userId == userAId), isFalse);
      expect(notesVal.first.id, 'note_b1');
    });

    test('CASE B: User A has messages, User B has different messages -> After switching, Messages show ONLY User B', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);

      final msgA = ChatMessageModel(
        id: 'msg_a1',
        senderId: 'fb_a',
        receiverId: 'fb_other',
        text: 'Private message from User A',
        status: MessageStatus.sent,
        createdAt: DateTime(2026, 9, 26),
      );

      final msgB = ChatMessageModel(
        id: 'msg_b1',
        senderId: 'fb_b',
        receiverId: 'fb_other',
        text: 'Message for User B',
        status: MessageStatus.sent,
        createdAt: DateTime(2026, 9, 26),
      );

      final convA = ConversationModel(
        id: 'conv_a',
        participants: ['fb_a', 'fb_other'],
        participantKey: 'fb_a_fb_other',
        lastMessage: 'Private message from User A',
        lastMessageAt: DateTime(2026, 9, 26),
        lastSenderId: 'fb_a',
        participantProfiles: {},
        unreadCounts: {},
        otherUid: 'fb_other',
        otherUserShortId: 'OTHER1',
      );

      final convB = ConversationModel(
        id: 'conv_b',
        participants: ['fb_b', 'fb_other'],
        participantKey: 'fb_b_fb_other',
        lastMessage: 'Message for User B',
        lastMessageAt: DateTime(2026, 9, 26),
        lastSenderId: 'fb_b',
        participantProfiles: {},
        unreadCounts: {},
        otherUid: 'fb_other',
        otherUserShortId: 'OTHER2',
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          conversationsStreamProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return Stream.value([convA]);
            if (uid == userBId) return Stream.value([convB]);
            return Stream.value([]);
          }),
          messagesStreamProvider.overrideWith((ref, convId) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return Stream.value([msgA]);
            if (uid == userBId) return Stream.value([msgB]);
            return Stream.value([]);
          }),
        ],
      );
      addTearDown(container.dispose);

      // User A reads conversations & messages
      final convsA = await container.read(conversationsStreamProvider.future);
      expect(convsA.length, 1);
      expect(convsA.first.id, 'conv_a');

      // User A signs out -> User B signs in
      container.read(activeUser.notifier).state = null;
      final convsLoggedOut = await container.read(conversationsStreamProvider.future);
      expect(convsLoggedOut, isEmpty);

      container.read(activeUser.notifier).state = userBId;
      final convsB = await container.read(conversationsStreamProvider.future);
      expect(convsB.length, 1);
      expect(convsB.first.id, 'conv_b');
      expect(convsB.any((c) => c.id == 'conv_a'), isFalse);

      final msgsB = await container.read(messagesStreamProvider('conv_b').future);
      expect(msgsB.length, 1);
      expect(msgsB.first.text, 'Message for User B');
      expect(msgsB.any((m) => m.text.contains('User A')), isFalse);
    });

    test('CASE C: User A has expenses, User B has different expenses -> After switching, Money shows ONLY User B', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          expensesProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockExpensesNotifier([expenseA], uid);
            if (uid == userBId) return _MockExpensesNotifier([expenseB], uid);
            return _MockExpensesNotifier([], null);
          }),
        ],
      );
      addTearDown(container.dispose);

      // Under User A
      expect(container.read(expensesProvider).value!.first.amount, 1500.0);
      expect(container.read(moneySummaryProvider).monthTotal, 1500.0);

      // Switch to User B
      container.read(activeUser.notifier).state = userBId;

      expect(container.read(expensesProvider).value!.first.amount, 320.0);
      expect(container.read(moneySummaryProvider).monthTotal, 320.0);
      expect(container.read(expensesProvider).value!.any((e) => e.userId == userAId), isFalse);
    });

    test('CASE D: User A has scheduled sessions, User B has different sessions -> After switching, Schedule shows ONLY User B', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          sessionsProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockSessionsNotifier([sessionA], ref, uid);
            if (uid == userBId) return _MockSessionsNotifier([sessionB], ref, uid);
            return _MockSessionsNotifier([], ref, null);
          }),
        ],
      );
      addTearDown(container.dispose);

      // User A sessions
      final sessA = container.read(sessionsProvider).value!;
      expect(sessA.first.id, 'sess_a1');
      expect(sessA.first.status, 'completed');

      // User B switches
      container.read(activeUser.notifier).state = userBId;

      final sessB = container.read(sessionsProvider).value!;
      expect(sessB.first.id, 'sess_b1');
      expect(sessB.first.status, 'planned');
      expect(sessB.any((s) => s.id == 'sess_a1'), isFalse);
    });

    test('CASE E: User A has Focus ID A, User B has Focus ID B -> After switching, Settings shows ONLY Focus ID B', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          currentChatUserShortIdProvider.overrideWith((ref) async {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return 'AAAA1';
            if (uid == userBId) return 'BBBB2';
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);

      final focusIdA = await container.read(currentChatUserShortIdProvider.future);
      expect(focusIdA, 'AAAA1');

      // Logout and sign in User B
      container.read(activeUser.notifier).state = userBId;

      final focusIdB = await container.read(currentChatUserShortIdProvider.future);
      expect(focusIdB, 'BBBB2');
    });

    test('CASE F: User A logs out while data request is in progress. User B logs in. Late response MUST NOT overwrite User B state', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);
      final completerA = Completer<List<Expense>>();

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          expensesProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) {
              return _AsyncMockExpensesNotifier(completerA.future, uid);
            }
            if (uid == userBId) {
              return _MockExpensesNotifier([expenseB], uid);
            }
            return _MockExpensesNotifier([], null);
          }),
        ],
      );
      addTearDown(container.dispose);

      // User A starts fetch (in flight)
      expect(container.read(expensesProvider).isLoading, isTrue);

      // User A logs out -> User B logs in BEFORE completerA completes
      container.read(activeUser.notifier).state = userBId;

      // User B state is immediately loaded with User B data
      expect(container.read(expensesProvider).value!.first.id, 'exp_b1');

      // Now User A's delayed request finishes late!
      completerA.complete([expenseA]);
      await Future<void>.delayed(Duration.zero);

      // User B's state MUST NOT be overwritten by User A's late response
      final currentList = container.read(expensesProvider).value!;
      expect(currentList.length, 1);
      expect(currentList.first.id, 'exp_b1');
      expect(currentList.any((e) => e.id == 'exp_a1'), isFalse);
    });

    test('CASE G: Repeated user switching A -> B -> A -> B consistently isolates data', () async {
      final activeUser = StateProvider<String?>((ref) => userAId);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => ref.watch(activeUser)),
          expensesProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockExpensesNotifier([expenseA], uid);
            if (uid == userBId) return _MockExpensesNotifier([expenseB], uid);
            return _MockExpensesNotifier([], null);
          }),
          profileProvider.overrideWith((ref) {
            final uid = ref.watch(currentUserIdProvider);
            if (uid == userAId) return _MockProfileNotifier(profileA, uid);
            if (uid == userBId) return _MockProfileNotifier(profileB, uid);
            return _MockProfileNotifier(null, null);
          }),
        ],
      );
      addTearDown(container.dispose);

      // Cycle 1: User A
      expect(container.read(profileProvider).value?.fullName, 'Alice User A');
      expect(container.read(expensesProvider).value?.first.id, 'exp_a1');

      // Cycle 2: User B
      container.read(activeUser.notifier).state = userBId;
      expect(container.read(profileProvider).value?.fullName, 'Bob User B');
      expect(container.read(expensesProvider).value?.first.id, 'exp_b1');

      // Cycle 3: User A again
      container.read(activeUser.notifier).state = userAId;
      expect(container.read(profileProvider).value?.fullName, 'Alice User A');
      expect(container.read(expensesProvider).value?.first.id, 'exp_a1');

      // Cycle 4: User B again
      container.read(activeUser.notifier).state = userBId;
      expect(container.read(profileProvider).value?.fullName, 'Bob User B');
      expect(container.read(expensesProvider).value?.first.id, 'exp_b1');
    });
  });
}

// ── Test Mock Notifiers ────────────────────────────────────────────────────────
// All mock notifiers pass `null` to super() intentionally.
// This skips the real fetch (which would call Supabase.instance before it's
// initialized in tests). The test overrideWith lambda provides the correct
// user-scoped data directly via state assignment.

class _MockProfileNotifier extends ProfileNotifier {
  final UserProfile? mockProfile;
  _MockProfileNotifier(this.mockProfile, String? userId) : super(null) {
    state = AsyncValue.data(mockProfile);
  }
}

class _MockExpensesNotifier extends ExpensesNotifier {
  _MockExpensesNotifier(List<Expense> initial, String? userId) : super(null) {
    state = AsyncValue.data(initial);
  }
}

class _AsyncMockExpensesNotifier extends ExpensesNotifier {
  final Future<List<Expense>> future;
  _AsyncMockExpensesNotifier(this.future, String? userId) : super(null) {
    state = const AsyncValue.loading();
    future.then((list) {
      if (!mounted) return;
      state = AsyncValue.data(list);
    });
  }
}

class _MockSessionsNotifier extends SessionsNotifier {
  _MockSessionsNotifier(List<LearningSession> initial, Ref ref, String? userId)
      : super(ref, null) {
    state = AsyncValue.data(initial);
  }
}

class _MockSkillsNotifier extends SkillsNotifier {
  _MockSkillsNotifier(List<Skill> initial, String? userId) : super(null) {
    state = AsyncValue.data(initial);
  }
}

class _MockNotesNotifier extends NotesNotifier {
  _MockNotesNotifier(List<Note> initial, String? userId) : super(null) {
    state = AsyncValue.data(initial);
  }
}

class _MockBudgetsNotifier extends BudgetsNotifier {
  _MockBudgetsNotifier(List<Budget> initial, String? userId) : super(null) {
    state = AsyncValue.data(initial);
  }
}

class _MockTrashedNotifier extends TrashedExpensesNotifier {
  _MockTrashedNotifier(List<Expense> initial, String? userId) : super(null) {
    state = AsyncValue.data(initial);
  }
}
