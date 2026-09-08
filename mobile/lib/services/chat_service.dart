import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

const String _allowedChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;

  static String generateRandomShortId() {
    final rand = Random.secure();
    return List.generate(5, (_) => _allowedChars[rand.nextInt(_allowedChars.length)]).join();
  }

  /// Ensures user has a permanent 5-character shortUserId.
  static Future<String> ensureUserChatId(String uid, [String? displayName]) async {
    if (uid.isEmpty) throw Exception('User UID required');

    final cleanName = displayName?.trim() ?? '';
    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();

    if (userSnap.exists && userSnap.data()?['shortUserId'] != null) {
      final existingShortId = userSnap.data()!['shortUserId'] as String;
      if (cleanName.isNotEmpty && userSnap.data()?['displayName'] != cleanName) {
        await userRef.set({'displayName': cleanName, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        await _firestore.collection('userIds').doc(existingShortId).set({'displayName': cleanName}, SetOptions(merge: true));
      }
      return existingShortId;
    }

    int attempts = 0;
    while (attempts < 10) {
      attempts++;
      final candidateId = generateRandomShortId();
      final lookupRef = _firestore.collection('userIds').doc(candidateId);

      try {
        final assignedId = await _firestore.runTransaction<String>((tx) async {
          final lookupSnap = await tx.get(lookupRef);
          if (lookupSnap.exists) {
            throw Exception('COLLISION');
          }

          tx.set(userRef, {
            'shortUserId': candidateId,
            'displayName': cleanName,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          tx.set(lookupRef, {
            'uid': uid,
            'displayName': cleanName,
            'createdAt': FieldValue.serverTimestamp(),
          });

          return candidateId;
        });

        return assignedId;
      } catch (e) {
        if (e.toString().contains('COLLISION')) {
          continue;
        }
        debugPrint('Error generating short user ID: $e');
        rethrow;
      }
    }

    throw Exception('Failed to generate unique Chat ID after maximum attempts');
  }

  /// Looks up Firebase UID by 5-character short Chat ID.
  static Future<String?> lookupUserByChatId(String shortUserId) async {
    final sanitized = shortUserId.trim().toUpperCase();
    if (sanitized.length < 4) return null;

    final lookupSnap = await _firestore.collection('userIds').doc(sanitized).get();
    if (lookupSnap.exists) {
      return lookupSnap.data()?['uid'] as String?;
    }
    return null;
  }

  /// Gets short Chat ID for a user UID.
  static Future<String?> getUserShortId(String uid) async {
    final userSnap = await _firestore.collection('users').doc(uid).get();
    if (userSnap.exists) {
      return userSnap.data()?['shortUserId'] as String?;
    }
    return null;
  }

  /// Gets or creates deterministic conversation between two UIDs.
  static Future<String> getOrCreateConversation(String currentUid, String targetUid) async {
    if (currentUid == targetUid) {
      throw Exception('Cannot message yourself');
    }

    final sorted = [currentUid, targetUid]..sort();
    final conversationId = '${sorted[0]}_${sorted[1]}';
    final convRef = _firestore.collection('conversations').doc(conversationId);

    try {
      final convSnap = await convRef.get();
      if (!convSnap.exists) {
        await convRef.set({
          'participants': sorted,
          'participantKey': conversationId,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastSenderId': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('getDoc check in getOrCreateConversation failed, performing set with merge: $e');
      await convRef.set({
        'participants': sorted,
        'participantKey': conversationId,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return conversationId;
  }

  /// Sends a message.
  static Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) throw Exception('Message cannot be empty');

    final messagesCol = _firestore.collection('conversations').doc(conversationId).collection('messages');
    final docRef = await messagesCol.add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': cleanText,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'seenAt': null,
    });

    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.update({
      'lastMessage': cleanText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    return docRef.id;
  }

  /// Marks incoming unread messages as seen and resets unread count.
  static Future<void> markMessagesAsSeen(String conversationId, String currentUid) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    await convRef.update({
      'unreadCounts.$currentUid': 0,
    }).catchError((e) {});

    final messagesCol = _firestore.collection('conversations').doc(conversationId).collection('messages');
    
    final querySnap = await messagesCol
        .where('receiverId', isEqualTo: currentUid)
        .where('status', isEqualTo: 'sent')
        .get();

    if (querySnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in querySnap.docs) {
      batch.update(doc.reference, {
        'status': 'seen',
        'seenAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Returns real-time stream of conversations for current user.
  static Stream<List<ConversationModel>> getConversationsStream(String currentUid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ConversationModel.fromFirestore(doc, currentUid)).toList();
      list.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Returns real-time stream of messages for a conversation.
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
}
