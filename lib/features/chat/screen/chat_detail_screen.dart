import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/data/message_repository.dart';
import 'package:talkest/features/chat/models/message.dart';
import 'package:talkest/features/chat/widget/message_bubble.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';

class ChatDetailScreen extends StatefulWidget {
  final String targetUserId;

  const ChatDetailScreen({super.key, required this.targetUserId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageRepository _messageRepository = MessageRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final AppUserRemoteDataSource _userRepository = AppUserRemoteDataSource();

  bool _isSending = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Data yang akan di-load
  String? _chatId;
  AppUser? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  Future<void> _loadChatData() async {
    try {
      // 1. Get current user
      final currentUser = context.read<AuthRepository>().currentUser;
      if (currentUser == null) {
        _showErrorAndRedirect('You must be logged in');
        return;
      }

      // 2. Validate: tidak bisa chat dengan diri sendiri
      if (widget.targetUserId == currentUser.uid) {
        _showErrorAndRedirect('You cannot chat with yourself');
        return;
      }

      // 3. Fetch target user data
      final targetUser = await _userRepository.getUserData(widget.targetUserId);
      if (targetUser == null) {
        _showErrorAndRedirect('User not found');
        return;
      }

      // 4. Get or create chat
      final chat = await _chatRepository.getOrCreateDirectChat(
        currentUser.uid,
        targetUser.uid,
      );

      // 5. Update state dengan data yang sudah di-load
      if (mounted) {
        setState(() {
          _chatId = chat.id;
          _otherUser = targetUser;
          _isLoading = false;
        });

        // Mark as read setelah data loaded
        _markAsRead();
      }
    } catch (e) {
      debugPrint('Error loading chat: $e');
      _showErrorAndRedirect('Failed to load chat');
    }
  }

  void _showErrorAndRedirect(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );

      // Redirect ke root setelah delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/');
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final currentUser = context.read<AuthRepository>().currentUser;
    if (currentUser != null && _chatId != null) {
      await _chatRepository.markAsRead(_chatId!, currentUser.uid);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = context.read<AuthRepository>().currentUser;
    if (currentUser == null) return;

    setState(() => _isSending = true);

    try {
      await _messageRepository.sendMessage(
        chatId: _chatId!,
        senderId: currentUser.uid,
        text: text,
        otherUserId: _otherUser!.uid,
      );

      _messageController.clear();

      // Wait a bit for the stream to update, then scroll
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leadingWidth: 56 + 4,
          leading: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CustomTextButton.icon(
              minWidth: 0,
              padding: EdgeInsets.symmetric(horizontal: 4),
              icon: Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          title: Row(
            children: [
              ClipOval(
                child: Container(
                  color: colorScheme.outline,
                  height: 36,
                  width: 36,
                  child: Icon(Icons.person, color: colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Loading...",
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading chat...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oops, error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Redirecting...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal state - data sudah loaded
    return AppScaffold(
      isUsingSafeArea: false,
      customAppBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.4),
            ),
          ),
        ),
        titleSpacing: AppScaffold.appBarDefaultConfig.titleSpacing,
        leadingWidth: AppScaffold.appBarDefaultConfig.leadingWidth,
        leading: AppScaffold.appBarDefaultConfig.leading(context),
        title: Row(
          children: [
            _otherUser!.photoUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _otherUser!.photoUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 18,
                        child: Text(
                          _otherUser!.displayName.isNotEmpty
                              ? _otherUser!.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 36,
                    width: 36,
                    child: CircleAvatar(
                      radius: 18,
                      child: Text(
                        _otherUser!.displayName.isNotEmpty
                            ? _otherUser!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _otherUser!.displayName,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
      ),
      body: (context, constraints) {
        return Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _messageRepository.getMessagesForChat(_chatId!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.\nSay hi! 👋',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  // Auto-scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isCurrentUser = message.senderId == currentUser.uid;

                      return MessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                      );
                    },
                  );
                },
              ),
            ),

            // Message input
            Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.4),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withValues(alpha: 0.05),
                //     blurRadius: 4,
                //     offset: const Offset(0, -2),
                //   ),
                // ],
              ),
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    // child: TextField(
                    //   controller: _messageController,
                    //   decoration: InputDecoration(
                    //     hintText: 'Type a message...',
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(24),
                    //       borderSide: BorderSide.none,
                    //     ),
                    //     filled: true,
                    //     fillColor: Theme.of(
                    //       context,
                    //     ).colorScheme.surfaceContainerHighest,
                    //     contentPadding: const EdgeInsets.symmetric(
                    //       horizontal: 16,
                    //       vertical: 10,
                    //     ),
                    //   ),
                    //   maxLines: null,
                    //   textCapitalization: TextCapitalization.sentences,
                    //   onSubmitted: (_) => _sendMessage(),
                    // ),
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 8,
                      decoration: InputDecoration(
                        // labelText: 'Google email',
                        hintText: 'Type a message...',
                        // prefixIcon: Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 4),
                        //   child: const Icon(Icons.email_outlined),
                        // ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.newline,
                      // onSubmitted: ,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : CustomFilledButton.icon(
                          icon: Icon(
                            Icons.send_rounded,
                            size: 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          minWidth: 0,
                          padding: EdgeInsets.all(15),
                          onPressed: _sendMessage,
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
