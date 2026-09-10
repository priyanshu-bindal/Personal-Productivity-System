import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_user_profile.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String participantKey;
  final Map<String, ChatUserProfile> participantProfiles;
  final Map<String, int> unreadCounts;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final DateTime? createdAt;
  final String otherUid;
  final String otherUserShortId;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantKey,
    required this.participantProfiles,
    required this.unreadCounts,
    required this.lastMessage,
    this.lastMessageAt,
    required this.lastSenderId,
    this.createdAt,
    required this.otherUid,
    required this.otherUserShortId,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc, String currentUid) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final participantsList = List<String>.from(data['participants'] as List? ?? []);

    final other = participantsList.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => currentUid,
    );

    // Parse participant profiles
    final profilesMap = <String, ChatUserProfile>{};
    if (data['participantProfiles'] is Map) {
      final rawProfiles = data['participantProfiles'] as Map;
      rawProfiles.forEach((key, val) {
        if (val is Map) {
          profilesMap[key.toString()] = ChatUserProfile.fromMap(
            key.toString(),
            Map<String, dynamic>.from(val),
          );
        }
      });
    }

    // Parse unread counts
    final unreads = <String, int>{};
    if (data['unreadCounts'] is Map) {
      final rawUnreads = data['unreadCounts'] as Map;
      rawUnreads.forEach((key, val) {
        if (val is num) {
          unreads[key.toString()] = val.toInt();
        }
      });
    }

    final targetProfile = profilesMap[other];

    return ConversationModel(
      id: doc.id,
      participants: participantsList,
      participantKey: (data['participantKey'] as String?) ?? doc.id,
      participantProfiles: profilesMap,
      unreadCounts: unreads,
      lastMessage: (data['lastMessage'] as String?) ?? '',
      lastMessageAt: _parseDateTime(data['lastMessageAt']),
      lastSenderId: (data['lastSenderId'] as String?) ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      otherUid: other,
      otherUserShortId: targetProfile?.shortUserId ?? '',
    );
  }

  static DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return null;
  }

  int unreadCountForUser(String uid) {
    return unreadCounts[uid] ?? 0;
  }

  String getOtherDisplayName(String currentUid) {
    final targetUid = otherUid.isNotEmpty ? otherUid : currentUid;
    return participantProfiles[targetUid]?.displayName ?? '';
  }

  String getOtherShortId(String currentUid) {
    final targetUid = otherUid.isNotEmpty ? otherUid : currentUid;
    final shortId = participantProfiles[targetUid]?.shortUserId;
    if (shortId != null && shortId.isNotEmpty) return shortId;
    return otherUserShortId.isNotEmpty ? otherUserShortId : '···';
  }

  String get shortAgo {
    if (lastMessageAt == null) return '';
    final diff = DateTime.now().difference(lastMessageAt!);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? participantKey,
    Map<String, ChatUserProfile>? participantProfiles,
    Map<String, int>? unreadCounts,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderId,
    DateTime? createdAt,
    String? otherUid,
    String? otherUserShortId,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantKey: participantKey ?? this.participantKey,
      participantProfiles: participantProfiles ?? this.participantProfiles,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      createdAt: createdAt ?? this.createdAt,
      otherUid: otherUid ?? this.otherUid,
      otherUserShortId: otherUserShortId ?? this.otherUserShortId,
    );
  }
}
