import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/data/auth_repository.dart';
import 'package:talkest/features/auth/data/datasource/app_user_remote_data_source.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/bloc/chat_detail/chat_detail_bloc.dart';
import 'package:talkest/features/chat/data/chat_repository.dart';
import 'package:talkest/features/chat/data/message_repository.dart';
import 'package:talkest/features/chat/models/message.dart';
import 'package:talkest/features/chat/widget/message_bubble.dart';
import 'package:talkest/shared/widgets/app_scaffold.dart';
import 'package:talkest/shared/widgets/custom_filled_button.dart';
import 'package:talkest/shared/widgets/custom_message_box.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';

class ChatDetailScreen extends StatefulWidget {
  final String targetUserId;

  const ChatDetailScreen({super.key, required this.targetUserId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageInputFocusNode = FocusNode();

  StickyDateController? _stickyDateController;

  @override
  void initState() {
    super.initState();
    context.read<ChatDetailBloc>().add(LoadChatDetail(widget.targetUserId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_stickyDateController != null) return;

    final paddingTop = MediaQuery.of(context).padding.top;

    _stickyDateController = StickyDateController(
      triggerLineY: paddingTop + kToolbarHeight + 18,
    );

    _stickyDateController!.attachScrollController(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stickyDateController?.dispose();
    _messageInputFocusNode.dispose();
    super.dispose();
  }

  void _showOtherUserProfile(BuildContext context, AppUser otherUser) {
    // unfocus textfield first
    if (_messageInputFocusNode.hasFocus) {
      _messageInputFocusNode.unfocus();
    }

    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // disable autofocus after closing bottom sheet
        enableDrag: true,
        isDismissible: true,
        builder: (_) => _OtherUserProfileBottomSheet(appUser: otherUser),
      ).then((_) {
        // make sure to still unfocus
        if (_messageInputFocusNode.hasFocus) {
          _messageInputFocusNode.unfocus();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return BlocConsumer<ChatDetailBloc, ChatDetailState>(
      listener: (context, state) {
        // Redirect
        if (state is ChatDetailError && state.shouldRedirect) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/');
          });
        }
      },
      builder: (context, state) {
        // LOADING STATE
        if (state is ChatDetailLoading) {
          return _buildLoadingScaffold(context);
        }

        // ERROR STATE
        if (state is ChatDetailError) {
          return _buildErrorScaffold(context, state.message);
        }

        // READY STATE
        if (state is ChatDetailReady) {
          return _buildChatScaffold(context, state, currentUser);
        }

        return const Scaffold(body: Center(child: Text('Unknown state')));
      },
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            icon: const Icon(Icons.arrow_back),
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
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading chat...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String message) {
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
              message,
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

  Widget _buildChatScaffold(
    BuildContext context,
    ChatDetailReady state,
    User currentUser,
  ) {
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
              child: InkWell(
                onLongPress: () {},
                onTap: () => _showOtherUserProfile(context, state.otherUser),
              ),
            ),
          ),
        ),
        titleSpacing: AppScaffold.appBarDefaultConfig.titleSpacing,
        leadingWidth: AppScaffold.appBarDefaultConfig.leadingWidth,
        leading: AppScaffold.appBarDefaultConfig.leading(context),
        title: IgnorePointer(
          ignoring: true,
          child: Row(
            children: [
              state.otherUser.photoUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: state.otherUser.photoUrl,
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
                            state.otherUser.displayName.isNotEmpty
                                ? state.otherUser.displayName[0].toUpperCase()
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
                          state.otherUser.displayName.isNotEmpty
                              ? state.otherUser.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.otherUser.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
      body: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: _MessageList(
                chatId: state.chatId,
                currentUser: currentUser,
                messages: state.messages,
                stickyDateController: _stickyDateController!,
                scrollController: _scrollController,
              ),
            ),
            _MessageInput(
              chatId: state.chatId,
              otherUser: state.otherUser,
              scrollController: _scrollController,
              focusNode: _messageInputFocusNode,
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// MESSAGE LIST
// =============================================================================
class _MessageList extends StatelessWidget {
  final String chatId;
  final User currentUser;
  final List<Message> messages;
  final StickyDateController stickyDateController;
  final ScrollController scrollController;

  _MessageList({
    super.key,
    required this.chatId,
    required this.currentUser,
    required this.messages,
    required this.stickyDateController,
    required this.scrollController,
  });

  /// Group messages by date (on DESC-ordered list, no manual reversal)
  List<_MessageGroup> _groupMessagesByDate(List<Message> messages) {
    final groups = <_MessageGroup>[];
    DateTime? currentDate;
    List<Message> currentMessages = [];

    // Messages are already DESC from Firestore
    for (final message in messages) {
      final messageDate = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );

      if (currentDate == null || !_isSameDay(currentDate, messageDate)) {
        if (currentMessages.isNotEmpty && currentDate != null) {
          groups.add(
            _MessageGroup(date: currentDate, messages: currentMessages),
          );
        }
        currentDate = messageDate;
        currentMessages = [message];
      } else {
        currentMessages.add(message);
      }
    }

    if (currentMessages.isNotEmpty && currentDate != null) {
      groups.add(_MessageGroup(date: currentDate, messages: currentMessages));
    }

    return groups;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _calculateTotalItems(List<_MessageGroup> groups) {
    int total = 0;
    for (final group in groups) {
      total += group.messages.length;
      total += 1; // Date divider
    }
    return total;
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    List<_MessageGroup> groups,
    String currentUserId,
    Map<String, GlobalKey> messageKeys,
  ) {
    int itemIndex = 0;

    // Iterate through groups
    for (final group in groups) {
      // Render messages first
      for (int i = 0; i < group.messages.length; i++) {
        if (itemIndex == index) {
          final message = group.messages[i];
          final isCurrentUser = message.senderId == currentUserId;
          return KeyedSubtree(
            key: messageKeys[message.id],
            child: MessageBubble(
              message: message,
              isCurrentUser: isCurrentUser,
            ),
          );
        }
        itemIndex++;
      }

      // Then render date divider (appears AFTER messages due to reverse)
      if (itemIndex == index) {
        return DateDivider(date: group.date);
      }
      itemIndex++;
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
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

    final groupedMessages = _groupMessagesByDate(messages);

    // Create keys
    final messageKeys = <String, GlobalKey>{};
    final messageDates = <String, DateTime>{};
    for (final message in messages) {
      messageKeys[message.id] = GlobalKey();
      final messageDate = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );
      messageDates[message.id] = messageDate;
    }

    // Update controller with message keys and dates
    stickyDateController.updateMessageKeys(messageKeys, messageDates);

    return Builder(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;

        return Stack(
          children: [
            ListView.builder(
              controller: scrollController,
              reverse: true,
              padding: EdgeInsets.only(top: topPadding, bottom: 8),
              itemCount: _calculateTotalItems(groupedMessages),
              itemBuilder: (context, index) {
                return _buildListItem(
                  context,
                  index,
                  groupedMessages,
                  currentUser.uid,
                  messageKeys,
                );
              },
            ),

            Positioned(
              top: topPadding + 4,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: StickyDateOverlay(controller: stickyDateController),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// MESSAGE INPUT
// =============================================================================
class _MessageInput extends StatefulWidget {
  final String chatId;
  final AppUser otherUser;
  final ScrollController scrollController;
  final FocusNode focusNode;

  const _MessageInput({
    super.key,
    required this.chatId,
    required this.otherUser,
    required this.scrollController,
    required this.focusNode,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    context.read<ChatDetailBloc>().add(SendMessageRequested(text));
    _messageController.clear();

    // after sending message request keyboard to still focus
    widget.focusNode.requestFocus();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!widget.scrollController.hasClients) return;

    widget.scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
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
            bottom: bottomPadding + 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  focusNode: widget.focusNode,
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
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<ChatDetailBloc, ChatDetailState>(
                buildWhen: (previous, current) {
                  if (previous is ChatDetailReady &&
                      current is ChatDetailReady) {
                    return previous.isSending != current.isSending;
                  }
                  return true;
                },
                builder: (context, state) {
                  final isSending = state is ChatDetailReady && state.isSending;

                  return isSending
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
                          padding: const EdgeInsets.all(15),
                          onPressed: () => _sendMessage(context),
                        );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// OTHER USER PROFILE BOTTOM SHEET
// =============================================================================

class _OtherUserProfileBottomSheet extends StatefulWidget {
  final AppUser appUser;

  const _OtherUserProfileBottomSheet({required this.appUser});

  @override
  State<_OtherUserProfileBottomSheet> createState() =>
      _OtherUserProfileBottomSheetState();
}

class _OtherUserProfileBottomSheetState
    extends State<_OtherUserProfileBottomSheet> {
  final CustomMessageBox _messageBox = CustomMessageBox();

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  children: [
                    CustomTextButton.icon(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      minWidth: 0,
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Avatar + Display Name + Tag
                Center(
                  child: Column(
                    children: [
                      _buildAvatar(context),
                      const SizedBox(height: 16),
                      // Display Name
                      Text(
                        widget.appUser.displayName.isNotEmpty
                            ? widget.appUser.displayName
                            : widget.appUser.name,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Username tag
                      Text(
                        '@${widget.appUser.name.toLowerCase().replaceAll(' ', '')}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Account Info Section
                Text(
                  'Account',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                _buildEmailItem(context),

                Padding(
                  padding: const EdgeInsets.only(bottom: 32 / 2),
                  child: Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),

                // Sign-in provider
                _buildInfoItem(
                  context,
                  label: 'Signed in with',
                  value: _capitalizeFirst(widget.appUser.provider),
                ),

                Divider(
                  height: 32,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),

                // Member since
                _buildInfoItem(
                  context,
                  label: 'Member since',
                  value: _formatDate(widget.appUser.createdAt),
                ),

                const SizedBox(height: 32),

                // Copy email notification
                _messageBox.showWidget(
                  margin: const EdgeInsets.only(bottom: 16),
                  infoBox: (msg) => InfoMessageBox(
                    message: msg,
                    isTransparent: true,
                    onDismiss: () => setState(() {
                      _messageBox.state = CustomMessageState.none;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = widget.appUser.displayName.isNotEmpty
        ? widget.appUser.displayName[0].toUpperCase()
        : '?';
    const double size = 88;

    if (widget.appUser.photoUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.appUser.photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircleAvatar(
            radius: size / 2,
            backgroundColor: colorScheme.primaryContainer,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: size / 2,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              initial,
              style: AppTextStyles.headlineLarge.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initial,
        style: AppTextStyles.headlineLarge.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildEmailItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Email',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomTextButton.icon(
                minWidth: 0,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: colorScheme.outline,
                ),
                onPressed: _copyEmailToClipboard,
              ),
              Flexible(
                child: Text(
                  widget.appUser.email,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyEmailToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.appUser.email));

    if (mounted) {
      setState(() {
        _messageBox.setValue(
          msg: 'Email copied to clipboard',
          state: CustomMessageState.info,
        );
      });
    }
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Data class for message grouping
class _MessageGroup {
  final DateTime date;
  final List<Message> messages;

  _MessageGroup({required this.date, required this.messages});
}

// Sticky date controller
class StickyDateController extends ChangeNotifier {
  final double triggerLineY;

  Map<String, GlobalKey> _messageKeys = {};
  Map<String, DateTime> _messageDates = {};
  ScrollController? _scrollController;
  Timer? _hideTimer;

  String? _currentDate;
  bool _isVisible = false;

  StickyDateController({required this.triggerLineY});

  String? get currentDate => _currentDate;

  bool get isVisible => _isVisible;

  void updateMessageKeys(
    Map<String, GlobalKey> keys,
    Map<String, DateTime> dates,
  ) {
    _messageKeys = keys;
    _messageDates = dates;
  }

  void attachScrollController(ScrollController controller) {
    _scrollController?.removeListener(_onScroll);
    _scrollController = controller;
    _scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController == null) return;

    // Show sticky when scrolling
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }

    // Reset hide timer
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      _isVisible = false;
      notifyListeners();
    });

    _updateStickyDateFromMessages();
  }

  void _updateStickyDateFromMessages() {
    if (_messageKeys.isEmpty || _messageDates.isEmpty) return;

    String? newDate;
    double closestDistance = double.infinity;
    DateTime? closestDate;

    // Find the message closest to the trigger line
    for (final entry in _messageKeys.entries) {
      final messageId = entry.key;
      final key = entry.value;
      final date = _messageDates[messageId];

      if (date == null) continue;

      final context = key.currentContext;
      if (context == null) continue;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      // Get message position and size
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // Calculate message center Y
      final messageCenterY = position.dy + (size.height / 2);

      // Calculate distance from trigger line
      final distance = (messageCenterY - triggerLineY).abs();

      // Find closest message
      if (distance < closestDistance) {
        closestDistance = distance;
        closestDate = date;
      }
    }

    if (closestDate != null) {
      newDate = _formatDate(closestDate);
    }

    if (newDate != _currentDate) {
      _currentDate = newDate;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (_isSameDay(dateOnly, today)) {
      return 'Today';
    } else if (_isSameDay(dateOnly, yesterday)) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _hideTimer?.cancel();
    super.dispose();
  }
}

// Simple date divider widget
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String text;
    if (dateOnly.isAtSameMomentAs(today)) {
      text = 'Today';
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      text = 'Yesterday';
    } else if (date.year == now.year) {
      text = DateFormat('MMMM d').format(date);
    } else {
      text = DateFormat('MMMM d, y').format(date);
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// Floating sticky date overlay
class StickyDateOverlay extends StatelessWidget {
  final StickyDateController controller;

  const StickyDateOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (!controller.isVisible || controller.currentDate == null) {
          return const SizedBox.shrink();
        }

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.currentDate!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
