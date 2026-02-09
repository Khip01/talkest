import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/data/message_repository.dart';
import 'package:talkest/features/chat/models/message.dart';

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

    debugPrint("BLOC[CHAT_DETAIL] INFO ------------   Sending message: $text");
    debugPrint(
      "BLOC[CHAT_DETAIL] INFO ------------   Current messages count: ${currentState.messages.length}",
    );

    emit(currentState.copyWith(isSending: true));

    try {
      await _messageRepository.sendMessage(
        chatId: currentState.chatId,
        senderId: currentUser.uid,
        text: text,
        otherUserId: currentState.otherUser.uid,
      );

      debugPrint(
        "BLOC[CHAT_DETAIL] SUCCESS ------------  Message sent successfully",
      );

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
      // Silently fail - not critical
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
