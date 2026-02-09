import 'package:cloud_firestore/cloud_firestore.dart';

class LastMessage {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final DateTime createdAt;
  final bool isDeleted;

  const LastMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory LastMessage.fromMap(Map<String, dynamic> map) {
    return LastMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      type: map['type'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
    };
  }
}
