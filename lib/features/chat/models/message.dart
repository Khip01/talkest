import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String text;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Message(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      type: data['type'] as String,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'type': type,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
