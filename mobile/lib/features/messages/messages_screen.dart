import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/conversation_model.dart';
import '../../providers/chat_provider.dart';
import 'widgets/conversation_tile.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCopyMyId(String myId) {
    Clipboard.setData(ClipboardData(text: myId));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  List<ConversationModel> _filterConversations(
      List<ConversationModel> conversations, String currentUid) {
    if (_searchQuery.isEmpty) return conversations;

    return conversations.where((conv) {
      final name = conv.getOtherDisplayName(currentUid).toLowerCase();
      final shortId = conv.getOtherShortId(currentUid).toLowerCase();
      return name.contains(_searchQuery) || shortId.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentFbUidAsync = ref.watch(firebaseChatUidProvider);
    final myShortIdAsync = ref.watch(currentChatUserShortIdProvider);
    final conversationsAsync = ref.watch(conversationsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFFF1F1F3)),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: TextStyle(
                color: Color(0xFFF1F1F3),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Private conversations, simply connected',
              style: TextStyle(
                color: Color(0xFF9A9AA5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: Color(0xFF93C5FD)),
            tooltip: 'New Conversation',
            onPressed: () => context.push('/messages/new'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0xFF2A2A31), height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B5B8C),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => context.push('/messages/new'),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF202025),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A31)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Color(0xFFF1F1F3), fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: const TextStyle(color: Color(0xFF70707A), fontSize: 13.5),
                    prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF70707A), size: 16),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, color: Color(0xFF70707A), size: 14),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // Identity Card (Your Focus ID)
            myShortIdAsync.when(
              data: (myId) {
                if (myId == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x2EFFFFFF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0x333B82F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x6693C5FD)),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(LucideIcons.hash, color: Color(0xFFBFDBFE), size: 14),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'YOUR FOCUS ID',
                                  style: TextStyle(
                                    color: Color(0xFF9A9AA5),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  '#$myId',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: Color(0xFFBFDBFE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _handleCopyMyId(myId),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x33FFFFFF)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isCopied ? LucideIcons.check : LucideIcons.copy,
                                  size: 13,
                                  color: _isCopied ? const Color(0xFF60A5FA) : const Color(0xFFBFDBFE),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isCopied ? 'Copied' : 'Copy',
                                  style: TextStyle(
                                    color: _isCopied ? const Color(0xFF60A5FA) : const Color(0xFFBFDBFE),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),

            // Conversations List
            Expanded(
              child: currentFbUidAsync.when(
                data: (currentFbUid) {
                  if (currentFbUid == null) {
                    return const Center(
                      child: Text(
                        'Authentication bridge loading…',
                        style: TextStyle(color: Color(0xFF9A9AA5), fontSize: 13),
                      ),
                    );
                  }

                  return conversationsAsync.when(
                    data: (conversations) {
                      final filtered = _filterConversations(conversations, currentFbUid);

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF202025),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFF2A2A31)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    LucideIcons.messageSquare,
                                    color: Color(0xFF7E9ED4),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: Color(0xFFF1F1F3),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Start a private conversation using a Focus ID.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF9A9AA5),
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/messages/new'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B5B8C),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(LucideIcons.plus, size: 16),
                                  label: const Text(
                                    'Start New Chat',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final conv = filtered[index];
                          return ConversationTile(
                            conversation: conv,
                            currentUid: currentFbUid,
                            onTap: () {
                              context.push(
                                '/messages/chat/${conv.id}',
                                extra: {
                                  'otherChatId': conv.getOtherShortId(currentFbUid),
                                  'otherDisplayName': conv.getOtherDisplayName(currentFbUid),
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF3B5B8C),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Failed to load conversations: $err',
                        style: const TextStyle(color: Color(0xFFEF5B5B), fontSize: 13),
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF3B5B8C),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Chat service notice: $err',
                    style: const TextStyle(color: Color(0xFFEF5B5B), fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
