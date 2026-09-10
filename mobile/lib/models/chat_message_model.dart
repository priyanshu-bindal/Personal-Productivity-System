import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum MessageStatus {
  sending,
  sent,
  seen;

  static MessageStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'seen':
        return MessageStatus.seen;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }

  String toValue() {
    switch (this) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.seen:
        return 'seen';
      case MessageStatus.sent:
        return 'sent';
    }
  }
}

class DetailedTimestamp {
  final String dateLine;
  final String timeLine;
  final String fullStr;

  const DetailedTimestamp({
    required this.dateLine,
    required this.timeLine,
    required this.fullStr,
  });
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageStatus status;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.status,
    this.createdAt,
    this.deliveredAt,
    this.seenAt,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      status: MessageStatus.fromString(data['status'] as String?),
      createdAt: _parseDateTime(data['createdAt']),
      deliveredAt: _parseDateTime(data['deliveredAt']),
      seenAt: _parseDateTime(data['seenAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'status': status.toValue(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : FieldValue.serverTimestamp(),
      'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? seenAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      seenAt: seenAt ?? this.seenAt,
    );
  }

  String get formattedTime {
    if (createdAt == null) return '';
    return DateFormat('hh:mm a').format(createdAt!);
  }

  static DetailedTimestamp? formatDetailedTimestamp(DateTime? dt) {
    if (dt == null) return null;
    final now = DateTime.now();
    final isToday = now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day;

    final timeLine = DateFormat('hh:mm:ss a').format(dt);

    if (isToday) {
      return DetailedTimestamp(
        dateLine: 'Today',
        timeLine: timeLine,
        fullStr: 'Today at $timeLine',
      );
    } else if (isYesterday) {
      return DetailedTimestamp(
        dateLine: 'Yesterday',
        timeLine: timeLine,
        fullStr: 'Yesterday at $timeLine',
      );
    } else {
      final dateLine = DateFormat('MMMM d, y').format(dt);
      return DetailedTimestamp(
        dateLine: dateLine,
        timeLine: timeLine,
        fullStr: '$dateLine at $timeLine',
      );
    }
  }
}
