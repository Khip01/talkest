import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/datasources.dart';
import 'package:talkest/features/chat/bloc/chat_list/chat_list_bloc.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/screen/embeded_landing_screen.dart';
import 'package:talkest/features/chat/widget/chat_tile.dart';
import 'package:talkest/features/chat/widget/start_chat_bottom_sheet.dart';
import 'package:talkest/shared/utils/embed_context.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final embedContext = EmbedContext.fromUri(GoRouterState.of(context).uri);
    final currentUser = context.read<AuthRepository>().currentUser;

    // Embed mode + not authenticated: show blur overlay with CTA
    if (embedContext.isEmbed && currentUser == null) {
      return Scaffold(body: EmbededLandingScreen());
    }

    return BlocProvider(
      create: (context) {
        final bloc = ChatListBloc(
          authRepository: context.read<AuthRepository>(),
          chatRepository: ChatRepository(),
          userRepository: AppUserRemoteDataSource(),
        );

        // Dispatch correct event based on embed mode
        if (embedContext.isValidEmbed) {
          bloc.add(OpenOrCreateEmbedChat(embedContext.targetUid!));
        } else if (!embedContext.isEmbed) {
          bloc.add(const LoadChatList());
        }

        return bloc;
      },
      child: _ChatListView(embedContext: embedContext),
    );
  }
}

class _ChatListView extends StatelessWidget {
  final EmbedContext embedContext;

  const _ChatListView({required this.embedContext});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Not authenticated...")));
    }

    // Embed mode validation: show error if targetUid is missing
    if (embedContext.isMissingTargetUid) {
      return _EmbedErrorScreen(
        title: "Invalid embed configuration",
        subtitle: "Missing targetUid parameter",
      );
    }

    return BlocListener<ChatListBloc, ChatListState>(
      listener: (context, state) {
        // Auto-redirect to chat detail in embed mode when chat list is loaded
        if (state is ChatListLoaded &&
            embedContext.isEmbed &&
            embedContext.isValidEmbed) {
          // Navigate immediately to chat detail with clean embed URL
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              // context.go(
              //   '/chat/${embedContext.targetUid}?embed=1&targetUid=${embedContext.targetUid}',
              // );
              context.goNamed(
                'chat_detail',
                pathParameters: {
                  'id': embedContext.targetUid!,
                  // Sesuai dengan path: 'chat/:id'
                },
                queryParameters: {
                  'embed': '1',
                  'targetUid': embedContext.targetUid!,
                  // Masuk ke sini agar jadi ?targetUid=...
                },
              );
            }
          });
        }

        // // Show error and redirect on embed error
        // if (state is ChatListError &&
        //     state.shouldRedirect &&
        //     embedContext.isEmbed) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(state.message),
        //       backgroundColor: Theme.of(context).colorScheme.error,
        //     ),
        //   );
        //   Future.delayed(const Duration(seconds: 2), () {
        //     if (context.mounted) {
        //       context.goNamed('root');
        //     }
        //   });
        // }
      },
      child: AppScaffold(
        // Hide FAB in embed mode
        floatingActionButton: embedContext.isEmbed
            ? null
            : CustomFilledButton.text(
                minWidth: 0,
                icon: const Icon(Icons.message_rounded),
                text: "New Chat",
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
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
              // Loading state with embed-specific message
              if (state is ChatListLoading || state is EmbedChatReady) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 2),
                      if (embedContext.isEmbed) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Opening chat...",
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              if (state is ChatListError) {
                // In embed mode with redirect error, show special error screen
                if (embedContext.isEmbed && state.shouldRedirect) {
                  return _EmbedErrorScreen(
                    title: "Chat user not found",
                    subtitle:
                        "Embed mode canceled. \nRedirecting you to the main page...",
                    showRedirecting: true,
                  );
                }

                final ColorScheme colorScheme = Theme.of(context).colorScheme;

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon(
                      //   Icons.error_outline,
                      //   size: 64,
                      //   color: Theme.of(context).colorScheme.error,
                      // ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      // const SizedBox(height: 16),
                      // Text(
                      //   state.message,
                      //   textAlign: TextAlign.center,
                      //   style: Theme.of(context).textTheme.bodyLarge,
                      // ),
                      const SizedBox(height: 24),
                      Text(
                        "Chat user not found",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!embedContext.isEmbed) ...[
                        const SizedBox(height: 16),
                        CustomTextButton.text(
                          onPressed: () => context.read<ChatListBloc>().add(
                            const LoadChatList(),
                          ),
                          textColor: colorScheme.primary,
                          text: "Refresh",
                        ),
                      ],
                    ],
                  ),
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
                        // Preserve embed query params when navigating (clean URL format)
                        if (embedContext.isEmbed) {
                          // context.go('/chat/${item.otherUser.uid}?embed=1');
                          context.goNamed(
                            'chat_detail',
                            pathParameters: {
                              'id': embedContext.targetUid!,
                              // Sesuai dengan path: 'chat/:id'
                            },
                            queryParameters: {
                              'embed': '1',
                              'targetUid': embedContext.targetUid!,
                              // Masuk ke sini agar jadi ?targetUid=...
                            },
                          );
                        } else {
                          context.goNamed(
                            'chat_detail',
                            pathParameters: {'id': item.otherUser.uid},
                          );
                        }
                      },
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

// Error screen for embed mode with auto-redirect
class _EmbedErrorScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showRedirecting;

  const _EmbedErrorScreen({
    required this.title,
    required this.subtitle,
    this.showRedirecting = false,
  });

  @override
  State<_EmbedErrorScreen> createState() => _EmbedErrorScreenState();
}

class _EmbedErrorScreenState extends State<_EmbedErrorScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showRedirecting) {
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) {
          context.goNamed('root');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.showRedirecting) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Redirecting...",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
