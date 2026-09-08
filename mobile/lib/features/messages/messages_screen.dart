import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/conversation_model.dart';
import '../../services/chat_service.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_service.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String? _currentUid;
  String? _userChatId;
  bool _isLoadingAuth = true;
  final Map<String, String> _shortIdCache = {};

  @override
  void initState() {
    super.initState();
    _initAuthAndChat();
  }

  Future<void> _initAuthAndChat() async {
    final uid = SupabaseService.currentUserId;
    if (uid != null) {
      _currentUid = uid;
      await FirebaseService.ensureFirebaseAuth(uid);
      final chatId = await ChatService.ensureUserChatId(uid);
      if (mounted) {
        setState(() {
          _userChatId = chatId;
          _isLoadingAuth = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingAuth = false);
      }
    }
  }

  Future<String> _getShortId(String otherUid) async {
    if (_shortIdCache.containsKey(otherUid)) {
      return _shortIdCache[otherUid]!;
    }
    final shortId = await ChatService.getUserShortId(otherUid);
    if (shortId != null) {
      _shortIdCache[otherUid] = shortId;
      return shortId;
    }
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 24),
              onPressed: () => context.push('/messages/new'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingAuth
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _currentUid == null
                ? const Center(child: Text('Please sign in to access messages', style: TextStyle(color: AppColors.textSecondary)))
                : Column(
                    children: [
                      // User's own Chat ID banner
                      if (_userChatId != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.messageSquare, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              const Text('Your Chat ID: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text(
                                _userChatId!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: _userChatId!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Chat ID copied to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(LucideIcons.copy, color: AppColors.primary, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Conversations Stream List
                      Expanded(
                        child: StreamBuilder<List<ConversationModel>>(
                          stream: ChatService.getConversationsStream(_currentUid!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error loading chats: ${snapshot.error}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                              );
                            }

                            final conversations = snapshot.data ?? [];

                            if (conversations.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: const Icon(LucideIcons.messageSquare, size: 40, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Your conversations will appear here',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Share your Chat ID or start a conversation by entering another person\'s Chat ID.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: () => context.push('/messages/new'),
                                        icon: const Icon(LucideIcons.plus, size: 18),
                                        label: const Text('Start a Conversation'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: conversations.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final conv = conversations[index];
                                final otherUid = conv.otherUserUid;

                                return FutureBuilder<String>(
                                  future: _getShortId(otherUid),
                                  builder: (context, shortIdSnap) {
                                    final displayId = shortIdSnap.data ?? '...';
                                    final timeStr = conv.lastMessageAt != null
                                        ? '${conv.lastMessageAt!.hour.toString().padLeft(2, '0')}:${conv.lastMessageAt!.minute.toString().padLeft(2, '0')}'
                                        : '';

                                    final unreadCount = conv.getUnreadCount(_currentUid!);

                                    return InkWell(
                                      onTap: () => context.push('/messages/${conv.id}?otherId=$displayId'),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.card,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                displayId.length >= 2 ? displayId.substring(0, 2) : '?',
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        displayId,
                                                        style: const TextStyle(
                                                          color: AppColors.textPrimary,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          fontFamily: 'monospace',
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      Text(
                                                        timeStr,
                                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    conv.lastMessage.isNotEmpty ? conv.lastMessage : 'No messages yet',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (unreadCount > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                constraints: const BoxConstraints(minWidth: 20),
                                                height: 20,
                                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0x2622C7A8),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0x4D22C7A8)),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Color(0xFF2DD4BF),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
