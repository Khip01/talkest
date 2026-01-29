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

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

/// UI-ready model combining chat with resolved user data
class ChatListItem extends Equatable {
  final Chat chat;
  final AppUser otherUser;

  const ChatListItem({required this.chat, required this.otherUser});

  @override
  List<Object?> get props => [chat, otherUser];
}
