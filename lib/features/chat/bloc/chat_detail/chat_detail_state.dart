part of 'chat_detail_bloc.dart';

abstract class ChatDetailState {
  const ChatDetailState();
}

class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading();
}

class ChatDetailReady extends ChatDetailState {
  final String chatId;
  final AppUser otherUser;
  final List<Message> messages;
  final bool isSending;

  const ChatDetailReady({
    required this.chatId,
    required this.otherUser,
    required this.messages,
    this.isSending = false,
  });

  ChatDetailReady copyWith({
    String? chatId,
    AppUser? otherUser,
    List<Message>? messages,
    bool? isSending,
  }) {
    return ChatDetailReady(
      chatId: chatId ?? this.chatId,
      otherUser: otherUser ?? this.otherUser,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatDetailError extends ChatDetailState {
  final String message;
  final bool shouldRedirect;

  const ChatDetailError({required this.message, this.shouldRedirect = true});
}
