import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';

/// Resolves the authenticated Firebase UID bridged from the active Supabase user.
final firebaseChatUidProvider = FutureProvider<String?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  return await FirebaseService.ensureFirebaseAuth(user.id, user.email);
});

/// Resolves the current user's 5-character Focus ID.
final currentChatUserShortIdProvider = FutureProvider<String?>((ref) async {
  final fbUid = await ref.watch(firebaseChatUidProvider.future);
  if (fbUid == null) return null;

  final user = SupabaseService.currentUser;
  final name = user?.userMetadata?['full_name'] as String? ??
      user?.userMetadata?['name'] as String? ??
      user?.email?.split('@').first ??
      '';

  return await ChatService.ensureUserChatId(fbUid, name);
});

/// Real-time stream of conversations for the current user.
final conversationsStreamProvider = StreamProvider<List<ConversationModel>>((ref) {
  final fbUidAsync = ref.watch(firebaseChatUidProvider);

  return fbUidAsync.when(
    data: (fbUid) {
      if (fbUid == null) return Stream.value(<ConversationModel>[]);
      return ChatService.getConversationsStream(fbUid);
    },
    loading: () => Stream.value(<ConversationModel>[]),
    error: (e, _) => Stream.value(<ConversationModel>[]),
  );
});

/// Real-time stream of messages for a specific conversation ID.
final messagesStreamProvider =
    StreamProvider.family<List<ChatMessageModel>, String>((ref, conversationId) {
  return ChatService.getMessagesStream(conversationId);
});

/// Real-time stream of total unread messages count across all conversations.
final totalUnreadChatCountProvider = StreamProvider<int>((ref) {
  final fbUidAsync = ref.watch(firebaseChatUidProvider);

  return fbUidAsync.when(
    data: (fbUid) {
      if (fbUid == null) return Stream.value(0);
      return ChatService.getTotalUnreadCountStream(fbUid);
    },
    loading: () => Stream.value(0),
    error: (e, _) => Stream.value(0),
  );
});
