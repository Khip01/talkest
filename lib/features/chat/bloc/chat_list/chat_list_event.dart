part of 'chat_list_bloc.dart';

abstract class ChatListEvent {
  const ChatListEvent();
}

class LoadChatList extends ChatListEvent {
  const LoadChatList();
}

class ChatListUpdated extends ChatListEvent {
  final List<Chat> chats;

  const ChatListUpdated(this.chats);
}

class OpenOrCreateEmbedChat extends ChatListEvent {
  final String targetUid;

  const OpenOrCreateEmbedChat(this.targetUid);
}
