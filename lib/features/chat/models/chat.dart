import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkest/features/chat/models/last_message.dart';

class Chat {
  final String id;
  final String type;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LastMessage? lastMessage;
  final Map<String, int> unreadCount;

  const Chat({
    required this.id,
    required this.type,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    required this.unreadCount,
  });

  factory Chat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Chat(
      id: doc.id,
      type: data['type'] as String,
      participants: List<String>.from(data['participants'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'] != null
          ? LastMessage.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
    };
  }

  /// Get the other participant UID (for direct chats)
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((uid) => uid != currentUserId);
  }
}
