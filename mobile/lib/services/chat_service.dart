import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/chat_user_profile.dart';
import '../models/conversation_model.dart';
import 'firebase_service.dart';

const String _allowedChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class ChatService {
  static FirebaseFirestore get _firestore => FirebaseService.firestore;

  /// Generates a random 5-character uppercase alphanumeric ID avoiding ambiguous characters.
  static String generateRandomShortId() {
    final rand = Random.secure();
    return List.generate(
      5,
      (_) => _allowedChars[rand.nextInt(_allowedChars.length)],
    ).join();
  }

  /// Ensures the user has a permanent unique 5-character shortUserId.
  /// Strictly reproduces planner/src/lib/firebase/chatService.ts ensureUserChatId.
  static Future<String> ensureUserChatId(String uid, [String? displayName]) async {
    if (uid.isEmpty) throw ArgumentError('User UID is required');

    final cleanName = displayName?.trim() ?? '';
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();

    if (userSnap.exists && userSnap.data()?['shortUserId'] != null) {
      final existingShortId = userSnap.data()!['shortUserId'] as String;
      if (cleanName.isNotEmpty && userSnap.data()?['displayName'] != cleanName) {
        await userRef.set({
          'displayName': cleanName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final lookupRef = _firestore.collection('userIds').doc(existingShortId);
        await lookupRef.set({
          'displayName': cleanName,
        }, SetOptions(merge: true));
      }
      return existingShortId;
    }

    // Generate unique Chat ID using Firestore transaction
    int attempts = 0;
    while (attempts < 10) {
      attempts++;
      final candidateId = generateRandomShortId();
      final userIdLookupRef = _firestore.collection('userIds').doc(candidateId);

      try {
        final assignedId = await _firestore.runTransaction<String>((transaction) async {
          final lookupSnap = await transaction.get(userIdLookupRef);
          if (lookupSnap.exists) {
            throw Exception('COLLISION');
          }

          transaction.set(
            userRef,
            {
              'shortUserId': candidateId,
              'displayName': cleanName,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.set(
            userIdLookupRef,
            {
              'uid': uid,
              'displayName': cleanName,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );

          return candidateId;
        });

        return assignedId;
      } catch (err) {
        if (err.toString().contains('COLLISION')) {
          continue;
        }
        debugPrint('Error during Chat ID generation transaction: $err');
        rethrow;
      }
    }

    throw Exception('Failed to generate unique Chat ID after maximum attempts');
  }

  /// Finds a user's Firebase UID and info by their 5-character Chat ID.
  static Future<Map<String, dynamic>?> lookupUserByChatId(String shortUserId) async {
    final sanitizedId = shortUserId.trim().toUpperCase();
    if (sanitizedId.length < 4) return null;

    final lookupRef = _firestore.collection('userIds').doc(sanitizedId);
    final lookupSnap = await lookupRef.get();

    if (lookupSnap.exists) {
      final data = lookupSnap.data();
      return {
        'uid': data?['uid'] as String?,
        'displayName': data?['displayName'] as String?,
      };
    }
    return null;
  }

  /// Gets short Chat ID for a given user UID.
  static Future<String?> getUserShortId(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      return userSnap.data()?['shortUserId'] as String?;
    }
    return null;
  }

  /// Gets full UserProfile (shortUserId + displayName) for a given user UID.
  static Future<ChatUserProfile?> getUserProfile(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (userSnap.exists) {
      final data = userSnap.data() ?? {};
      return ChatUserProfile(
        uid: uid,
        shortUserId: (data['shortUserId'] as String?) ?? '',
        displayName: (data['displayName'] as String?) ?? '',
      );
    }
    return null;
  }

  /// Deterministically creates or retrieves a 1-to-1 conversation between two users.
  static Future<String> getOrCreateConversation(String currentUid, String targetUid) async {
    if (currentUid == targetUid) {
      throw ArgumentError('Cannot message yourself');
    }

    final sortedUids = [currentUid, targetUid]..sort();
    final conversationId = '${sortedUids[0]}_${sortedUids[1]}';
    final convRef = _firestore.collection('conversations').doc(conversationId);

    // Fetch profiles for both participants to embed in the conversation doc
    final profiles = <String, Map<String, String>>{};
    try {
      final currentProf = await getUserProfile(currentUid);
      if (currentProf != null) {
        profiles[currentUid] = {
          'shortUserId': currentProf.shortUserId,
          'displayName': currentProf.displayName,
        };
      }
    } catch (_) {}

    try {
      final targetProf = await getUserProfile(targetUid);
      if (targetProf != null) {
        profiles[targetUid] = {
          'shortUserId': targetProf.shortUserId,
          'displayName': targetProf.displayName,
        };
      }
    } catch (_) {}

    try {
      final convSnap = await convRef.get();
      if (!convSnap.exists) {
        await convRef.set({
          'participants': sortedUids,
          'participantKey': conversationId,
          'participantProfiles': profiles,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (profiles.isNotEmpty) {
        await convRef.set({
          'participantProfiles': profiles,
        }, SetOptions(merge: true));
      }
    } catch (err) {
      debugPrint('Fallback saving conversation doc: $err');
      await convRef.set({
        'participants': sortedUids,
        'participantKey': conversationId,
        'participantProfiles': profiles,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return conversationId;
  }

  /// Sends a direct message in a conversation.
  static Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) throw ArgumentError('Message text cannot be empty');

    final messagesColRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final docRef = await messagesColRef.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': cleanText,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
      'seenAt': null,
    });

    // Update last message preview and increment recipient's unread count atomically
    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.update({
      'lastMessage': cleanText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Marks incoming unread messages in a conversation as seen and resets recipient's unread count to 0.
  static Future<void> markMessagesAsSeen(String conversationId, String currentUid) async {
    if (conversationId.isEmpty || currentUid.isEmpty) return;

    // Reset unread count for current user on conversation document
    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.update({
      'unreadCounts.$currentUid': 0,
    }).catchError((_) {});

    try {
      final messagesColRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

      final querySnapshot = await messagesColRef
          .where('receiverId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'sent')
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final messageDoc in querySnapshot.docs) {
        batch.update(messageDoc.reference, {
          'status': 'seen',
          'seenAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (err) {
      debugPrint('Error marking messages as seen: $err');
    }
  }

  /// Real-time stream for user's conversations list, sorted by lastMessageAt descending.
  static Stream<List<ConversationModel>> getConversationsStream(String currentUid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc, currentUid))
          .toList();

      list.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }

  /// Real-time stream for messages within a specific conversation.
  static Stream<List<ChatMessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream of total unread messages count for badge display.
  static Stream<int> getTotalUnreadCountStream(String currentUid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['unreadCounts'] is Map) {
          final unreads = data['unreadCounts'] as Map;
          final count = unreads[currentUid];
          if (count is num) {
            total += count.toInt();
          }
        }
      }
      return total;
    });
  }
}
