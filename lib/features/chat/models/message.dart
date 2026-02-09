import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String text;
  final DateTime createdAt;

  // edit and delete fields
  final DateTime? editedAt;
  final bool isDeleted;

  // reply fields
  final String? replyToId;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final String? replyToText;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.text,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.replyToId,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToText,
  });

  /// whether this message has been edited at least once
  bool get isEdited => editedAt != null;

  /// whether this message is a reply to another message
  bool get isReply => replyToId != null;

  /// truncated reply preview text (max 100 chars)
  String get replyPreviewText {
    if (replyToText == null) return '';
    if (replyToText!.length <= 100) return replyToText!;
    return '${replyToText!.substring(0, 100)}...';
  }

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Message(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      type: data['type'] as String,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] as bool? ?? false,
      replyToId: data['replyToId'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      replyToSenderName: data['replyToSenderName'] as String?,
      replyToText: data['replyToText'] as String?,
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
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      'isDeleted': isDeleted,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
    };
  }

  Message copyWith({String? text, DateTime? editedAt, bool? isDeleted}) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      type: type,
      text: text ?? this.text,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId,
      replyToSenderId: replyToSenderId,
      replyToSenderName: replyToSenderName,
      replyToText: replyToText,
    );
  }
}
