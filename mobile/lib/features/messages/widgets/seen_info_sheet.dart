import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/chat_message_model.dart';

class SeenInfoSheet extends StatelessWidget {
  final ChatMessageModel message;
  final bool isOutgoing;

  const SeenInfoSheet({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  static Future<void> show(BuildContext context, ChatMessageModel message, bool isOutgoing) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SeenInfoSheet(
        message: message,
        isOutgoing: isOutgoing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seenFormatted = message.status == MessageStatus.seen
        ? ChatMessageModel.formatDetailedTimestamp(message.seenAt ?? message.createdAt)
        : null;
    final sentFormatted =
        ChatMessageModel.formatDetailedTimestamp(message.deliveredAt ?? message.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            decoration: BoxDecoration(
              color: const Color(0xE618181B), // rgba(24, 24, 27, 0.90)
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: const Color(0x332A2A31),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 32,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x4D70707A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header row: Status Icon + Title + Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildStatusIcon(message.status),
                        const SizedBox(width: 8),
                        Text(
                          message.status == MessageStatus.seen
                              ? 'Seen'
                              : message.status == MessageStatus.sent
                                  ? 'Sent'
                                  : 'Sending...',
                          style: const TextStyle(
                            color: Color(0xFFF1F1F3),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Color(0x8CFFFFFF), size: 18),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0x26FFFFFF), height: 1),
                const SizedBox(height: 14),

                // Delivery Info
                if (message.status == MessageStatus.sending) ...[
                  const Text(
                    'Sending message to recipient…',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 13.5,
                    ),
                  ),
                ] else if (message.status == MessageStatus.seen) ...[
                  const Text(
                    'SEEN AT',
                    style: TextStyle(
                      color: Color(0x80FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (seenFormatted != null) ...[
                    Text(
                      seenFormatted.dateLine,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      seenFormatted.timeLine,
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Seen by recipient',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ] else ...[
                  const Text(
                    'SENT AT',
                    style: TextStyle(
                      color: Color(0x80FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (sentFormatted != null) ...[
                    Text(
                      sentFormatted.dateLine,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sentFormatted.timeLine,
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Delivered to server',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 18),
                const Divider(color: Color(0x26FFFFFF), height: 1),
                const SizedBox(height: 14),

                // Copy Action Button
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.copy, color: Color(0xFF93C5FD), size: 18),
                        SizedBox(width: 12),
                        Text(
                          'Copy Message Text',
                          style: TextStyle(
                            color: Color(0xFFF1F1F3),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF70707A),
          ),
        );
      case MessageStatus.sent:
        return const Icon(LucideIcons.check, size: 18, color: Color(0xFF70707A));
      case MessageStatus.seen:
        return const Icon(LucideIcons.checkCheck, size: 18, color: Color(0xFF60A5FA));
    }
  }
}
