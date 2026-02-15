import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/data/message_repository.dart';
import 'package:talkest/features/chat/models/message.dart';
import 'package:talkest/services/notification_service.dart';

part 'chat_detail_event.dart';

part 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final AuthRepository _authRepository;
  final ChatRepository _chatRepository;
  final MessageRepository _messageRepository;
  final AppUserRemoteDataSource _userRepository;

  StreamSubscription<List<Message>>? _messageSubscription;
  String? _currentChatId;

  ChatDetailBloc({
    required AuthRepository authRepository,
    required ChatRepository chatRepository,
    required MessageRepository messageRepository,
    required AppUserRemoteDataSource userRepository,
  }) : _authRepository = authRepository,
       _chatRepository = chatRepository,
       _messageRepository = messageRepository,
       _userRepository = userRepository,
       super(const ChatDetailLoading()) {
    on<LoadChatDetail>(_onLoadChatDetail);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<SendMessageRequested>(_onSendMessageRequested);
    on<MarkAsReadRequested>(_onMarkAsReadRequested);
    on<ToggleMessageSelection>(_onToggleMessageSelection);
    on<ClearSelection>(_onClearSelection);
    on<StartEditMode>(_onStartEditMode);
    on<CancelEditMode>(_onCancelEditMode);
    on<EditMessageRequested>(_onEditMessageRequested);
    on<DeleteMessagesRequested>(_onDeleteMessagesRequested);
    on<StartReplyMode>(_onStartReplyMode);
    on<CancelReplyMode>(_onCancelReplyMode);
    on<CopyMessagesRequested>(_onCopyMessagesRequested);
  }

  Future<void> _onLoadChatDetail(
    LoadChatDetail event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(
        const ChatDetailError(
          message: 'You must be logged in',
          shouldRedirect: true,
        ),
      );
      return;
    }

    if (event.targetUserId == currentUser.uid) {
      emit(
        const ChatDetailError(
          message: 'You cannot chat with yourself',
          shouldRedirect: true,
        ),
      );
      return;
    }

    emit(const ChatDetailLoading());

    try {
      // Fetch target user
      final targetUser = await _userRepository.getUserData(event.targetUserId);
      if (targetUser == null) {
        emit(
          const ChatDetailError(
            message: 'User not found',
            shouldRedirect: true,
          ),
        );
        return;
      }

      // fetch current user's AppUser profile
      final currentAppUser = await _userRepository.getUserData(currentUser.uid);
      if (currentAppUser == null) {
        emit(
          const ChatDetailError(
            message: 'Failed to load your profile',
            shouldRedirect: true,
          ),
        );
        return;
      }

      // Get or create chat
      final chat = await _chatRepository.getOrCreateDirectChat(
        currentUser.uid,
        targetUser.uid,
      );

      _currentChatId = chat.id;

      // Subscribe to messages
      await _messageSubscription?.cancel();
      _messageSubscription = _messageRepository
          .getMessagesForChat(chat.id)
          .listen((messages) {
            add(MessagesUpdated(messages));
          });

      // Mark as read
      add(const MarkAsReadRequested());

      // Emit ready with empty messages initially
      emit(
        ChatDetailReady(
          chatId: chat.id,
          currentUser: currentAppUser,
          otherUser: targetUser,
          messages: const [],
        ),
      );
    } catch (e) {
      emit(
        ChatDetailError(
          message: 'Failed to load chat: $e',
          shouldRedirect: true,
        ),
      );
    }
  }

  Future<void> _onMessagesUpdated(
    MessagesUpdated event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatDetailReady) {
      debugPrint(
        "BLOC[CHAT_DETAIL] INFO ------------ Messages updated: ${event.messages.length} messages",
      );
      debugPrint(
        "BLOC[CHAT_DETAIL] INFO ------------ First message: ${event.messages.isNotEmpty ? event.messages.first.text : "empty"}",
      );

      emit(currentState.copyWith(messages: event.messages));

      add(const MarkAsReadRequested());
    }
  }

  Future<void> _onSendMessageRequested(
    SendMessageRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    final currentUser = _authRepository.currentUser;
    if (currentUser == null) return;

    final text = event.text.trim();
    if (text.isEmpty) return;

    // capture reply context before clearing
    final replyTo = currentState.replyingToMessage;
    String? replyToSenderName;
    if (replyTo != null) {
      replyToSenderName = replyTo.senderId == currentUser.uid
          ? 'You'
          : currentState.otherUser.displayName;
    }

    debugPrint("BLOC[CHAT_DETAIL] INFO ------------   Sending message: $text");

    emit(currentState.copyWith(isSending: true, clearReplying: true));

    try {
      await _messageRepository.sendMessage(
        chatId: currentState.chatId,
        senderId: currentUser.uid,
        text: text,
        otherUserId: currentState.otherUser.uid,
        replyToMessage: replyTo,
        replyToSenderName: replyToSenderName,
      );

      debugPrint(
        "BLOC[CHAT_DETAIL] SUCCESS ------------  Message sent successfully",
      );

      // Send push notification to receiver (mobile only, fire-and-forget)
      if (!kIsWeb) {
        _sendPushNotification(
          receiverEmail: currentState.otherUser.email,
          senderName: currentState.currentUser.displayName,
          messageText: text,
          chatId: currentState.chatId,
        );
      }

      final latestState = state;
      if (latestState is ChatDetailReady) {
        emit(latestState.copyWith(isSending: false));
      }
    } catch (e) {
      debugPrint(
        "BLOC[CHAT_DETAIL] ERROR ------------ Error sending message: $e",
      );

      final latestState = state;
      if (latestState is ChatDetailReady) {
        emit(latestState.copyWith(isSending: false));
      }
    }
  }

  Future<void> _onMarkAsReadRequested(
    MarkAsReadRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null || _currentChatId == null) return;

    try {
      await _chatRepository.markAsRead(_currentChatId!, currentUser.uid);
    } catch (e) {
      // silently fail - not critical
    }
  }

  // ===========================================================================
  // Selection handlers
  // ===========================================================================

  void _onToggleMessageSelection(
    ToggleMessageSelection event,
    Emitter<ChatDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    final selected = Set<String>.from(currentState.selectedMessageIds);
    if (selected.contains(event.message.id)) {
      selected.remove(event.message.id);
    } else {
      selected.add(event.message.id);
    }

    emit(currentState.copyWith(selectedMessageIds: selected));
  }

  void _onClearSelection(ClearSelection event, Emitter<ChatDetailState> emit) {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    emit(currentState.copyWith(selectedMessageIds: {}));
  }

  // ===========================================================================
  // Edit handlers
  // ===========================================================================

  void _onStartEditMode(StartEditMode event, Emitter<ChatDetailState> emit) {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    emit(
      currentState.copyWith(
        editingMessage: event.message,
        selectedMessageIds: {},
        clearReplying: true,
      ),
    );
  }

  void _onCancelEditMode(CancelEditMode event, Emitter<ChatDetailState> emit) {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    emit(currentState.copyWith(clearEditing: true));
  }

  Future<void> _onEditMessageRequested(
    EditMessageRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    final newText = event.newText.trim();
    if (newText.isEmpty) return;

    emit(currentState.copyWith(clearEditing: true));

    try {
      await _messageRepository.editMessage(
        chatId: currentState.chatId,
        messageId: event.messageId,
        newText: newText,
      );
    } catch (e) {
      debugPrint("BLOC[CHAT_DETAIL] ERROR ------------ Edit failed: $e");
    }
  }

  // ===========================================================================
  // Delete handler
  // ===========================================================================

  Future<void> _onDeleteMessagesRequested(
    DeleteMessagesRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    // clear selection right away
    emit(currentState.copyWith(selectedMessageIds: {}));

    try {
      for (final messageId in event.messageIds) {
        await _messageRepository.softDeleteMessage(
          chatId: currentState.chatId,
          messageId: messageId,
        );
      }
    } catch (e) {
      debugPrint("BLOC[CHAT_DETAIL] ERROR ------------ Delete failed: $e");
    }
  }

  // ===========================================================================
  // Reply handlers
  // ===========================================================================

  void _onStartReplyMode(StartReplyMode event, Emitter<ChatDetailState> emit) {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    emit(
      currentState.copyWith(
        replyingToMessage: event.message,
        selectedMessageIds: {},
        clearEditing: true,
      ),
    );
  }

  void _onCancelReplyMode(
    CancelReplyMode event,
    Emitter<ChatDetailState> emit,
  ) {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    emit(currentState.copyWith(clearReplying: true));
  }

  // ===========================================================================
  // Copy handler
  // ===========================================================================

  Future<void> _onCopyMessagesRequested(
    CopyMessagesRequested event,
    Emitter<ChatDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatDetailReady) return;

    // sort by createdAt ascending for logical order
    final sorted = List<Message>.from(event.messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final String textToCopy;

    if (sorted.length == 1) {
      // single message: copy plain text only
      textToCopy = sorted.first.text;
    } else {
      // multiple messages: format with sender info
      textToCopy = sorted
          .map((m) {
            final AppUser sender = m.senderId == currentState.currentUser.uid
                ? currentState.currentUser
                : currentState.otherUser;
            return '${sender.displayName} [${sender.name}] \u{1F4AC}: ${m.text}';
          })
          .join('\n');
    }

    await Clipboard.setData(ClipboardData(text: textToCopy));

    emit(currentState.copyWith(selectedMessageIds: {}));
  }

  // ===========================================================================
  // Push notification helper (fire-and-forget)
  // ===========================================================================

  /// Fetch receiver's FCM token and invoke Edge Function.
  void _sendPushNotification({
    required String receiverEmail,
    required String senderName,
    required String messageText,
    required String chatId,
  }) {
    Future(() async {
      try {
        final notificationService = NotificationService.instance;

        final fcmToken = await notificationService.getFcmTokenByEmail(
          receiverEmail,
        );
        if (fcmToken == null || fcmToken.isEmpty) {
          debugPrint(
            '[ChatDetailBloc] No FCM token found for $receiverEmail',
          );
          return;
        }

        // Truncate long messages for notification body
        final body = messageText.length > 200
            ? '${messageText.substring(0, 200)}...'
            : messageText;

        await notificationService.sendPushNotification(
          fcmToken: fcmToken,
          title: senderName,
          body: body,
          data: {'chatId': chatId},
        );
      } catch (e) {
        debugPrint('[ChatDetailBloc] Push notification error: $e');
      }
    });
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
