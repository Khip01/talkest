part of 'chat_detail_bloc.dart';

abstract class ChatDetailEvent {
  const ChatDetailEvent();
}

class LoadChatDetail extends ChatDetailEvent {
  final String targetUserId;

  const LoadChatDetail(this.targetUserId);
}

class MessagesUpdated extends ChatDetailEvent {
  final List<Message> messages;

  const MessagesUpdated(this.messages);
}

class SendMessageRequested extends ChatDetailEvent {
  final String text;

  const SendMessageRequested(this.text);
}

class MarkAsReadRequested extends ChatDetailEvent {
  const MarkAsReadRequested();
}
