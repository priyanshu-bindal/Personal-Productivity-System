import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/chat_message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isOutgoing;
  final VoidCallback onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive max bubble width:
    // Phones: ~78% of available width
    // Tablets / Wider viewports: capped at 540px or 65% of screen width
    final maxBubbleWidth = screenWidth > 700
        ? (screenWidth * 0.62).clamp(280.0, 560.0)
        : screenWidth * 0.78;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message Bubble with InkWell / GestureDetector for long press
            Material(
              color: Colors.transparent,
              child: InkWell(
                onLongPress: onLongPress,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                  bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                ),
                splashColor: isOutgoing
                    ? const Color(0x1F3B5B8C)
                    : const Color(0x1FFFFFFF),
                highlightColor: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: maxBubbleWidth,
                    minWidth: 44,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9.5,
                  ),
                  decoration: BoxDecoration(
                    color: isOutgoing
                        ? const Color(0x2E3B5B8C) // Subtle translucent sapphire blue
                        : const Color(0xFF1E1E23), // Clean dark slate surface
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                      bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isOutgoing
                          ? const Color(0x593B5B8C) // Subtle brand border
                          : const Color(0xFF282830), // Dark border
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Color(0xFFF1F1F3),
                      fontSize: 14,
                      height: 1.38,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
              ),
            ),

            // Timestamp & Status Indicator directly below bubble
            Padding(
              padding: EdgeInsets.only(
                top: 3,
                left: isOutgoing ? 0 : 4,
                right: isOutgoing ? 4 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    message.formattedTime,
                    style: const TextStyle(
                      color: Color(0xFF70707A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (isOutgoing) ...[
                    const SizedBox(width: 4),
                    _buildStatusIndicator(message.status),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFF70707A),
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          LucideIcons.check,
          size: 13,
          color: Color(0xFF70707A),
        );
      case MessageStatus.seen:
        return const Icon(
          LucideIcons.checkCheck,
          size: 14,
          color: Color(0xFF60A5FA), // light sapphire blue
        );
    }
  }
}

