import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String participantKey;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final DateTime? createdAt;
  final String otherUserUid;
  final Map<String, int> unreadCounts;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantKey,
    required this.lastMessage,
    this.lastMessageAt,
    required this.lastSenderId,
    this.createdAt,
    required this.otherUserUid,
    this.unreadCounts = const {},
  });

  int getUnreadCount(String currentUid) => unreadCounts[currentUid] ?? 0;

  factory ConversationModel.fromFirestore(DocumentSnapshot doc, String currentUid) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawParticipants = List<String>.from(data['participants'] as List? ?? []);
    final otherUid = rawParticipants.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => currentUid,
    );

    DateTime? parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    final rawUnread = data['unreadCounts'] as Map? ?? {};
    final parsedUnread = <String, int>{};
    rawUnread.forEach((k, v) {
      if (v is int) parsedUnread[k.toString()] = v;
      if (v is num) parsedUnread[k.toString()] = v.toInt();
    });

    return ConversationModel(
      id: doc.id,
      participants: rawParticipants,
      participantKey: data['participantKey'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: parseTimestamp(data['lastMessageAt']),
      lastSenderId: data['lastSenderId'] as String? ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      otherUserUid: otherUid,
      unreadCounts: parsedUnread,
    );
  }
}
