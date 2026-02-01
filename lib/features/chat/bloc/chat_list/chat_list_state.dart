part of 'chat_list_bloc.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListEmpty extends ChatListState {
  const ChatListEmpty();
}

class ChatListLoaded extends ChatListState {
  final List<ChatListItem> items;

  const ChatListLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class ChatListError extends ChatListState {
  final String message;
  final bool shouldRedirect;

  const ChatListError(this.message, {this.shouldRedirect = false});

  @override
  List<Object?> get props => [message, shouldRedirect];
}

class EmbedChatReady extends ChatListState {
  final String targetUid;

  const EmbedChatReady(this.targetUid);

  @override
  List<Object?> get props => [targetUid];
}

/// UI-ready model combining chat with resolved user data
class ChatListItem extends Equatable {
  final Chat chat;
  final AppUser otherUser;

  const ChatListItem({required this.chat, required this.otherUser});

  @override
  List<Object?> get props => [chat, otherUser];
}
