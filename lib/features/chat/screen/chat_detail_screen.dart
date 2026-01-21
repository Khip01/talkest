import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/data/message_repository.dart';
import 'package:talkest/features/chat/models/message.dart';
import 'package:talkest/features/chat/widget/message_bubble.dart';

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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
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
        appBar: AppBar(title: const Text('Error')),
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
    return Scaffold(
      appBar: AppBar(
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
                : CircleAvatar(
                    radius: 18,
                    child: Text(
                      _otherUser!.displayName.isNotEmpty
                          ? _otherUser!.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _otherUser!.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
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
                  return const Center(child: CircularProgressIndicator());
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
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
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: _sendMessage,
                            padding: EdgeInsets.zero,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
