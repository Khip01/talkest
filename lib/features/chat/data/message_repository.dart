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
    Message? replyToMessage,
    String? replyToSenderName,
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
      replyToId: replyToMessage?.id,
      replyToSenderId: replyToMessage?.senderId,
      replyToSenderName: replyToSenderName,
      replyToText: replyToMessage?.text,
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

  /// Edit an existing message text
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final now = DateTime.now();

    final messageRef = _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .doc(messageId);

    await messageRef.update({
      'text': newText,
      'editedAt': Timestamp.fromDate(now),
    });

    // update lastMessage if this was the latest message
    await _updateLastMessageIfNeeded(chatId, messageId, newText: newText);
  }

  /// Soft delete a message (mark as deleted, clear text)
  Future<void> softDeleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final messageRef = _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .doc(messageId);

    await messageRef.update({'isDeleted': true, 'text': ''});

    // update lastMessage if this was the latest message
    await _updateLastMessageIfNeeded(chatId, messageId, isDeleted: true);
  }

  /// Update lastMessage on the chat doc if the edited/deleted message
  /// is the current lastMessage
  Future<void> _updateLastMessageIfNeeded(
    String chatId,
    String messageId, {
    String? newText,
    bool isDeleted = false,
  }) async {
    final chatDoc = await _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .get();
    if (!chatDoc.exists) return;

    final data = chatDoc.data();
    if (data == null) return;

    final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
    if (lastMessage == null) return;
    if (lastMessage['id'] != messageId) return;

    final updates = <String, dynamic>{};
    if (newText != null) {
      updates['lastMessage.text'] = newText;
    }
    if (isDeleted) {
      updates['lastMessage.text'] = '';
      updates['lastMessage.isDeleted'] = true;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection(_chatsCollection).doc(chatId).update(updates);
    }
  }
}
