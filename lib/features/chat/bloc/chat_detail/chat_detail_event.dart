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

// =============================================================================
// Selection events
// =============================================================================

class ToggleMessageSelection extends ChatDetailEvent {
  final Message message;

  const ToggleMessageSelection(this.message);
}

class ClearSelection extends ChatDetailEvent {
  const ClearSelection();
}

// =============================================================================
// Edit events
// =============================================================================

class StartEditMode extends ChatDetailEvent {
  final Message message;

  const StartEditMode(this.message);
}

class CancelEditMode extends ChatDetailEvent {
  const CancelEditMode();
}

class EditMessageRequested extends ChatDetailEvent {
  final String messageId;
  final String newText;

  const EditMessageRequested({required this.messageId, required this.newText});
}

// =============================================================================
// Delete events
// =============================================================================

class DeleteMessagesRequested extends ChatDetailEvent {
  final List<String> messageIds;

  const DeleteMessagesRequested(this.messageIds);
}

// =============================================================================
// Reply events
// =============================================================================

class StartReplyMode extends ChatDetailEvent {
  final Message message;

  const StartReplyMode(this.message);
}

class CancelReplyMode extends ChatDetailEvent {
  const CancelReplyMode();
}

// =============================================================================
// Copy event
// =============================================================================

class CopyMessagesRequested extends ChatDetailEvent {
  final List<Message> messages;

  const CopyMessagesRequested(this.messages);
}
