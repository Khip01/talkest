part of 'chat_detail_bloc.dart';

abstract class ChatDetailState {
  const ChatDetailState();
}

class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading();
}

class ChatDetailReady extends ChatDetailState {
  final String chatId;
  final AppUser currentUser;
  final AppUser otherUser;
  final List<Message> messages;
  final bool isSending;

  // selection mode
  final Set<String> selectedMessageIds;

  // editing mode: the message currently being edited
  final Message? editingMessage;

  // reply mode: the message currently being replied to
  final Message? replyingToMessage;

  const ChatDetailReady({
    required this.chatId,
    required this.currentUser,
    required this.otherUser,
    required this.messages,
    this.isSending = false,
    this.selectedMessageIds = const {},
    this.editingMessage,
    this.replyingToMessage,
  });

  /// whether any messages are currently selected
  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  /// whether the user is currently editing a message
  bool get isEditingMode => editingMessage != null;

  /// whether the user is currently replying to a message
  bool get isReplyingMode => replyingToMessage != null;

  /// get the selected Message objects from the list
  List<Message> get selectedMessages {
    return messages.where((m) => selectedMessageIds.contains(m.id)).toList();
  }

  ChatDetailReady copyWith({
    String? chatId,
    AppUser? currentUser,
    AppUser? otherUser,
    List<Message>? messages,
    bool? isSending,
    Set<String>? selectedMessageIds,
    Message? editingMessage,
    Message? replyingToMessage,
    bool clearEditing = false,
    bool clearReplying = false,
  }) {
    return ChatDetailReady(
      chatId: chatId ?? this.chatId,
      currentUser: currentUser ?? this.currentUser,
      otherUser: otherUser ?? this.otherUser,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      selectedMessageIds: selectedMessageIds ?? this.selectedMessageIds,
      editingMessage: clearEditing
          ? null
          : (editingMessage ?? this.editingMessage),
      replyingToMessage: clearReplying
          ? null
          : (replyingToMessage ?? this.replyingToMessage),
    );
  }
}

class ChatDetailError extends ChatDetailState {
  final String message;
  final bool shouldRedirect;

  const ChatDetailError({required this.message, this.shouldRedirect = true});
}
