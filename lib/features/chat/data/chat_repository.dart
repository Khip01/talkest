import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkest/features/chat/models/chat.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  static const String _chatsCollection = 'chats';

  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream all chats for current user, ordered by updatedAt DESC
  Stream<List<Chat>> getChatsForUser(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList();
        });
  }

  /// Get a single chat by ID
  // Future<Chat?> getChatById(String chatId) async {
  //   final doc = await _firestore.collection(_chatsCollection).doc(chatId).get();
  //   if (!doc.exists) return null;
  //   return Chat.fromFirestore(doc);
  // }

  /// Get or create a direct chat between two users
  Future<Chat> getOrCreateDirectChat(String userId1, String userId2) async {
    // Query for existing chat
    final querySnapshot = await _firestore
        .collection(_chatsCollection)
        .where('type', isEqualTo: 'direct')
        .where('participants', arrayContains: userId1)
        .get();

    // Check if chat with both participants exists
    for (var doc in querySnapshot.docs) {
      final chat = Chat.fromFirestore(doc);
      if (chat.participants.contains(userId2)) {
        return chat;
      }
    }

    // Create new chat
    final now = DateTime.now();
    final newChatRef = _firestore.collection(_chatsCollection).doc();
    final newChat = Chat(
      id: newChatRef.id,
      type: 'direct',
      participants: [userId1, userId2],
      createdAt: now,
      updatedAt: now,
      lastMessage: null,
      unreadCount: {userId1: 0, userId2: 0},
    );

    await newChatRef.set(newChat.toFirestore());
    return newChat;
  }

  /// Mark messages as read for current user
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection(_chatsCollection).doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }
}
