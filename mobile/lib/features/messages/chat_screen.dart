import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherChatId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherChatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentUid;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUid = SupabaseService.currentUserId;
    if (_currentUid != null) {
      ChatService.markMessagesAsSeen(widget.conversationId, _currentUid!).catchError((e) {
        debugPrint('Error marking messages as seen: $e');
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _currentUid == null || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final sortedParts = widget.conversationId.split('_');
      final receiverId = sortedParts.firstWhere(
        (id) => id != _currentUid,
        orElse: () => _currentUid!,
      );

      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: _currentUid!,
        receiverId: receiverId,
        text: text,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: AppColors.accentRose),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayId = widget.otherChatId.isNotEmpty ? widget.otherChatId : 'Chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat ID',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            Text(
              displayId,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Messages Stream
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: ChatService.getMessagesStream(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Send a message to start.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isOutgoing = msg.senderId == _currentUid;

                      return Align(
                        alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isOutgoing ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
                              bottomRight: Radius.circular(isOutgoing ? 4 : 18),
                            ),
                            border: isOutgoing ? null : Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isOutgoing ? Colors.white : AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                              if (isOutgoing) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (msg.status == MessageStatus.sending)
                                      const Icon(LucideIcons.clock, size: 12, color: Colors.white70)
                                    else if (msg.status == MessageStatus.sent)
                                      const Icon(LucideIcons.check, size: 14, color: Colors.white70)
                                    else if (msg.status == MessageStatus.seen)
                                      const Icon(LucideIcons.checkCheck, size: 14, color: Color(0xFF4ADE80)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Input Composer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        fillColor: AppColors.surface,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _handleSendMessage,
                    icon: const Icon(LucideIcons.send, color: AppColors.primary, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
