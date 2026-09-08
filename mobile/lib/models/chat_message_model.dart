import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, seen }

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageStatus status;
  final DateTime? createdAt;
  final DateTime? seenAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.status,
    this.createdAt,
    this.seenAt,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    MessageStatus parsedStatus = MessageStatus.sent;
    final statusStr = data['status'] as String?;
    if (statusStr == 'sending') {
      parsedStatus = MessageStatus.sending;
    } else if (statusStr == 'seen') {
      parsedStatus = MessageStatus.seen;
    } else {
      parsedStatus = MessageStatus.sent;
    }

    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      status: parsedStatus,
      createdAt: parseTimestamp(data['createdAt']),
      seenAt: parseTimestamp(data['seenAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'status': status.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
    };
  }
}
