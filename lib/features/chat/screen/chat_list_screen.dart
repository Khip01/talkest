import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/chat/bloc/chat_list/chat_list_bloc.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/widget/chat_tile.dart';
import 'package:talkest/features/chat/widget/start_chat_bottom_sheet.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatListBloc(
        authRepository: context.read<AuthRepository>(),
        chatRepository: ChatRepository(),
        userRepository: AppUserRemoteDataSource(),
      )..add(const LoadChatList()),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not authenticated...")));
    }

    return AppScaffold(
      floatingActionButton: CustomFilledButton.text(
        minWidth: 0,
        icon: const Icon(Icons.message_rounded),
        text: "New Chat",
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            builder: (_) => ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.7),
                  child: const StartChatBottomSheet(),
                ),
              ),
            ),
          );
        },
      ),
      body: (context, constraints) {
        return BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            if (state is ChatListLoading) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (state is ChatListError) {
              return Center(
                child: Text(state.message, textAlign: TextAlign.center),
              );
            }

            if (state is ChatListEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No chats yet",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start a conversation!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is ChatListLoaded) {
              return ListView.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];

                  return ChatTile(
                    chat: item.chat,
                    otherUser: item.otherUser,
                    currentUserId: currentUser.uid,
                    onTap: () {
                      context.goNamed(
                        'chat_detail',
                        pathParameters: {'id': item.otherUser.uid},
                      );
                    },
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
