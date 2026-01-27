import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkest/features/chat/models/last_message.dart';
import 'package:talkest/features/chat/models/message.dart';

class MessageRepository {
  final FirebaseFirestore _firestore;
  static const String _chatsCollection = 'chats';
  static const String _messagesSubcollection = 'messages';

  MessageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream messages for a chat, ordered by createdAt ASC
  Stream<List<Message>> getMessagesForChat(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc))
              .toList();
        });
  }

  /// Send a new message (with batch update to parent chat)
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required String otherUserId,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // 1. Create message document
    final messageRef = _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .doc();

    final message = Message(
      id: messageRef.id,
      chatId: chatId,
      senderId: senderId,
      type: 'text',
      text: text,
      createdAt: now,
    );

    batch.set(messageRef, message.toFirestore());

    // 2. Update parent chat document
    final chatRef = _firestore.collection(_chatsCollection).doc(chatId);

    final lastMessage = LastMessage(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      type: 'text',
      createdAt: now,
    );

    batch.update(chatRef, {
      'lastMessage': lastMessage.toMap(),
      'updatedAt': Timestamp.fromDate(now),
      'unreadCount.$otherUserId': FieldValue.increment(1),
    });

    // 3. Commit batch
    await batch.commit();
  }
}
