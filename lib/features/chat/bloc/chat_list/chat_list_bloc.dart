import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/models/chat.dart';

part 'chat_list_event.dart';

part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final AuthRepository _authRepository;
  final ChatRepository _chatRepository;
  final AppUserRemoteDataSource _userRepository;

  StreamSubscription<List<Chat>>? _chatSubscription;

  final Map<String, AppUser> _userCache = {};

  ChatListBloc({
    required AuthRepository authRepository,
    required ChatRepository chatRepository,
    required AppUserRemoteDataSource userRepository,
  }) : _authRepository = authRepository,
       _chatRepository = chatRepository,
       _userRepository = userRepository,
       super(const ChatListLoading()) {
    on<LoadChatList>(_onLoadChatList);
    on<ChatListUpdated>(_onChatListUpdated);
  }

  Future<void> _onLoadChatList(
    LoadChatList event,
    Emitter<ChatListState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(const ChatListError('Not authenticated'));
      return;
    }

    emit(const ChatListLoading());

    try {
      await _chatSubscription?.cancel();
      _chatSubscription = _chatRepository
          .getChatsForUser(currentUser.uid)
          .listen(
            (chats) {
              add(ChatListUpdated(chats));
            },
            onError: (error) {
              add(ChatListUpdated([]));
            },
          );
    } catch (e) {
      emit(ChatListError('Failed to load chats: $e'));
    }
  }

  Future<void> _onChatListUpdated(
    ChatListUpdated event,
    Emitter<ChatListState> emit,
  ) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(const ChatListError('Not authenticated'));
      return;
    }

    if (event.chats.isEmpty) {
      emit(const ChatListEmpty());
      return;
    }

    try {
      // Resolve all user data in parallel
      final items = await Future.wait(
        event.chats.map((chat) async {
          final otherUserId = chat.getOtherParticipantId(currentUser.uid);

          // Check otherUser cache
          AppUser? otherUser = _userCache[otherUserId];

          if (otherUser == null) {
            otherUser = await _userRepository.getUserData(otherUserId);
            if (otherUser == null) {
              throw Exception('User not found: $otherUserId');
            }
            // Save to cache
            _userCache[otherUserId] = otherUser;
          }

          return ChatListItem(chat: chat, otherUser: otherUser);

        }),
      );

      emit(ChatListLoaded(items));
    } catch (e) {
      emit(ChatListError('Failed to resolve user data: $e'));
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    _userCache.clear();
    return super.close();
  }
}
