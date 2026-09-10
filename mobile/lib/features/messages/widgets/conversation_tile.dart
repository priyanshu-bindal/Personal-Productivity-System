import 'package:flutter/material.dart';
import '../../../models/conversation_model.dart';
import 'id_marker.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUid;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.getOtherDisplayName(currentUid);
    final otherShortId = conversation.getOtherShortId(currentUid);
    final unreadCount = conversation.unreadCountForUser(currentUid);
    final timeStr = conversation.shortAgo;
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: hasUnread ? const Color(0x0D3B5B8C) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasUnread ? const Color(0x333B5B8C) : const Color(0x1A2A2A31),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            IdMarker(
              id: otherShortId,
              name: otherName,
              size: IdMarkerSize.md,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              if (otherName.isNotEmpty) ...[
                                TextSpan(
                                  text: '$otherName ',
                                  style: const TextStyle(
                                    color: Color(0xFFF1F1F3),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: '($otherShortId)',
                                  style: const TextStyle(
                                    color: Color(0xFF70707A),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ] else ...[
                                TextSpan(
                                  text: '#$otherShortId',
                                  style: const TextStyle(
                                    color: Color(0xFFF1F1F3),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: hasUnread ? const Color(0xFF7E9ED4) : const Color(0xFF70707A),
                            fontSize: 11,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage.isNotEmpty
                              ? conversation.lastMessage
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasUnread ? const Color(0xFFF1F1F3) : const Color(0xFF8A8A93),
                            fontSize: 12.5,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x333B5B8C), // rgba(59, 91, 140, 0.20)
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0x593B5B8C), // rgba(59, 91, 140, 0.35)
                              width: 1,
                            ),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Color(0xFF7E9ED4),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
