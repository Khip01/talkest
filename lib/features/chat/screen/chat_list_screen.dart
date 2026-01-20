import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/models/chat.dart';
import 'package:talkest/features/chat/widget/chat_tile.dart';
import 'package:talkest/features/chat/widget/start_chat_bottom_sheet.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final chatRepository = ChatRepository();
    final userRepository = AppUserRemoteDataSource();

    return AppScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => const StartChatBottomSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
      body: (context, constraints) {
        return StreamBuilder<List<Chat>>(
          stream: chatRepository.getChatsForUser(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint("Error: ${snapshot.error}");
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
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
                      'No chats yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUserId = chat.getOtherParticipantId(currentUser.uid);

                return FutureBuilder<AppUser?>(
                  future: userRepository.getUserData(otherUserId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Loading...'),
                      );
                    }

                    final otherUser = userSnapshot.data!;

                    return ChatTile(
                      chat: chat,
                      otherUser: otherUser,
                      currentUserId: currentUser.uid,
                      onTap: () {
                        // context.push('/chat/${otherUserId}');
                        context.goNamed('chat_detail', pathParameters: {'id': otherUserId});
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
