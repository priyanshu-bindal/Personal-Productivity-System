/// Model representing a user profile in FocusFlow Chat.
/// Compatible with Firestore users/{uid} and embedded participantProfiles.
class ChatUserProfile {
  final String uid;
  final String shortUserId;
  final String displayName;

  const ChatUserProfile({
    required this.uid,
    required this.shortUserId,
    required this.displayName,
  });

  factory ChatUserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return ChatUserProfile(
      uid: uid,
      shortUserId: (data['shortUserId'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shortUserId': shortUserId,
      'displayName': displayName,
    };
  }

  ChatUserProfile copyWith({
    String? uid,
    String? shortUserId,
    String? displayName,
  }) {
    return ChatUserProfile(
      uid: uid ?? this.uid,
      shortUserId: shortUserId ?? this.shortUserId,
      displayName: displayName ?? this.displayName,
    );
  }
}
