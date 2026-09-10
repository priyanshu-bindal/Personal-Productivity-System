import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/chat_message_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/id_marker.dart';
import 'widgets/message_composer.dart';
import 'widgets/seen_info_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? otherChatId;
  final String? otherDisplayName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherChatId,
    this.otherDisplayName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isNearBottom = true;
  bool _hasUnseenAtBottom = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final nearBottom = (maxScroll - currentScroll) <= 100;

    if (nearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        if (nearBottom) _hasUnseenAtBottom = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom([bool animated = true]) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _handleSendMessage(String text) async {
    final currentFbUid = await ref.read(firebaseChatUidProvider.future);
    if (currentFbUid == null) return;

    setState(() => _isSending = true);

    try {
      final sortedParts = widget.conversationId.split('_');
      final receiverId = sortedParts.firstWhere(
        (id) => id != currentFbUid,
        orElse: () => currentFbUid,
      );

      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentFbUid,
        receiverId: receiverId,
        text: text,
      );

      // Scroll to bottom after user sends
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _scrollToBottom(true);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: const Color(0xFFEF5B5B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _markSeenIfNeeded(List<ChatMessageModel> messages, String currentFbUid) {
    final hasUnseen = messages.any(
      (m) => m.receiverId == currentFbUid && m.status != MessageStatus.seen,
    );

    if (hasUnseen) {
      ChatService.markMessagesAsSeen(widget.conversationId, currentFbUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFbUidAsync = ref.watch(firebaseChatUidProvider);
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));

    final currentFbUid = currentFbUidAsync.value;

    final headerShortId = widget.otherChatId?.isNotEmpty == true
        ? widget.otherChatId!
        : 'Chat';
    final headerDisplayName = widget.otherDisplayName;

    return Scaffold(
      backgroundColor: const Color(0xFF111113),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AppBar(
              backgroundColor: const Color(0xF218181B), // rgba(24, 24, 27, 0.95)
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              leadingWidth: 48,
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFFF1F1F3), size: 20),
                onPressed: () => context.pop(),
                splashRadius: 20,
              ),
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    IdMarker(
                      id: headerShortId,
                      name: headerDisplayName,
                      size: IdMarkerSize.sm,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (headerDisplayName != null && headerDisplayName.isNotEmpty) ...[
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$headerDisplayName ',
                                    style: const TextStyle(
                                      color: Color(0xFFF1F1F3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '($headerShortId)',
                                    style: const TextStyle(
                                      color: Color(0xFF70707A),
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              '#$headerShortId',
                              style: const TextStyle(
                                color: Color(0xFFF1F1F3),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 1.5),
                          const Text(
                            'Private conversation',
                            style: TextStyle(
                              color: Color(0xFF70707A),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(color: Color(0xFF282830), height: 1),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111113),
            gradient: RadialGradient(
              center: Alignment(0.6, -0.7),
              radius: 1.2,
              colors: [
                Color(0x0F3B5B8C), // subtle sapphire glow top-right
                Color(0xFF111113),
              ],
            ),
          ),
          child: Column(
            children: [
              // Messages Stream Area
              Expanded(
                child: Stack(
                  children: [
                    messagesAsync.when(
                      data: (messages) {
                        if (currentFbUid != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _markSeenIfNeeded(messages, currentFbUid);
                          });
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1E),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFF282830)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.messageSquare,
                                      color: Color(0xFF7E9ED4),
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Private conversation',
                                    style: TextStyle(
                                      color: Color(0xFFF1F1F3),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Send a message to start chatting with ${headerDisplayName ?? "#$headerShortId"}.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF9A9AA5),
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Smart scroll behavior:
                        if (messages.length > _lastMessageCount) {
                          final wasInitialLoad = _lastMessageCount == 0;
                          _lastMessageCount = messages.length;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (wasInitialLoad || _isNearBottom) {
                              _scrollToBottom(true);
                            } else {
                              setState(() => _hasUnseenAtBottom = true);
                            }
                          });
                        }

                        // Build messages with adaptive spacing
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isOut = msg.senderId == currentFbUid;

                            final showDateDivider = _shouldShowDateDivider(messages, index);

                            // Calculate spacing to next message for tight grouping:
                            // If consecutive message from same sender: 4px; else: 10px
                            final bool isNextSameSender = index < messages.length - 1 &&
                                messages[index + 1].senderId == msg.senderId &&
                                !_shouldShowDateDivider(messages, index + 1);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateDivider) ...[
                                  _buildDateDivider(msg.createdAt),
                                ],
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isNextSameSender ? 4 : 10,
                                  ),
                                  child: ChatMessageBubble(
                                    message: msg,
                                    isOutgoing: isOut,
                                    onLongPress: () {
                                      SeenInfoSheet.show(context, msg, isOut);
                                    },
                                  ),
                                ),
                              ],
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
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Failed to load messages: $err',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFEF5B5B), fontSize: 13),
                          ),
                        ),
                      ),
                    ),

                    // "New Messages" Jump-to-Bottom Badge
                    if (_hasUnseenAtBottom)
                      Positioned(
                        bottom: 14,
                        right: 16,
                        child: FloatingActionButton.small(
                          backgroundColor: const Color(0xFF3B5B8C),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          onPressed: () {
                            _scrollToBottom(true);
                            setState(() => _hasUnseenAtBottom = false);
                          },
                          child: const Icon(LucideIcons.chevronDown, size: 20),
                        ),
                      ),
                  ],
                ),
              ),

              // Message Composer
              MessageComposer(
                onSend: _handleSendMessage,
                isSending: _isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowDateDivider(List<ChatMessageModel> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].createdAt;
    final previous = messages[index - 1].createdAt;
    if (current == null || previous == null) return false;

    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  Widget _buildDateDivider(DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final isToday = now.year == date.year && now.month == date.month && now.day == date.day;
    final dateStr = isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x332A2A31), // subtle dark pill
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x333B5B8C), width: 1),
          ),
          child: Text(
            dateStr,
            style: const TextStyle(
              color: Color(0xFF9A9AA5), // clear, properly visible text
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
