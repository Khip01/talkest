import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:talkest/app/theme/colors.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/chat/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final void Function(Offset position)? onSecondaryTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
    this.onSwipeReply,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // selection/highlight background
    final highlightColor = isDark
        ? AppColors.selectionHighlightDark
        : AppColors.selectionHighlightLight;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTapUp: kIsWeb && onSecondaryTap != null
          ? (details) => onSecondaryTap!(details.globalPosition)
          : null,
      child: _SwipeToReply(
        onSwipe: onSwipeReply,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: (isSelected || isHighlighted)
              ? highlightColor.withValues(alpha: 0.5)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
          child: Align(
            alignment: isCurrentUser
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: message.isDeleted
                    ? Colors.transparent
                    : isCurrentUser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(12)
                      : Radius.zero,
                  bottomRight: isCurrentUser
                      ? Radius.zero
                      : const Radius.circular(12),
                ),
                border: message.isDeleted
                    ? Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      )
                    : null,
              ),
              child: message.isDeleted
                  ? _DeletedMessageContent(colorScheme: colorScheme)
                  : _ActiveMessageContent(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      colorScheme: colorScheme,
                      isDark: isDark,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Deleted message content
// =============================================================================
class _DeletedMessageContent extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DeletedMessageContent({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Active (non-deleted) message content
// =============================================================================
class _ActiveMessageContent extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final ColorScheme colorScheme;
  final bool isDark;

  const _ActiveMessageContent({
    required this.message,
    required this.isCurrentUser,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentUser
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    Alignment alignContent = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: IntrinsicWidth(
        child: Column(
          // crossAxisAlignment: isCurrentUser
          //     ? CrossAxisAlignment.end
          //     : CrossAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // reply preview (if this message is a reply)
            if (message.isReply) ...[
              _ReplyPreview(
                senderName: message.replyToSenderName ?? 'Unknown',
                text: message.replyPreviewText,
                isCurrentUser: isCurrentUser,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 4),
            ],
        
            // message text
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
              textAlign: TextAlign.left,
            ),
        
            const SizedBox(height: 4),
        
            // timestamp + edited indicator
            Align(
              alignment: alignContent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.isEdited) ...[
                    Text(
                      'edited',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isCurrentUser
                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.5)
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrentUser
                          ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Reply preview inside a message bubble
// =============================================================================
class _ReplyPreview extends StatelessWidget {
  final String senderName;
  final String text;
  final bool isCurrentUser;
  final ColorScheme colorScheme;
  final bool isDark;

  const _ReplyPreview({
    required this.senderName,
    required this.text,
    required this.isCurrentUser,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark
        ? AppColors.replyAccentDark
        : AppColors.replyAccentLight;

    final bgColor = isCurrentUser
        ? colorScheme.primary.withValues(alpha: 0.1)
        : colorScheme.onSurface.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.only(left: 8, top: 6, right: 8, bottom: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: AppTextStyles.labelSmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isCurrentUser
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Swipe-to-reply gesture wrapper
// =============================================================================
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipe;

  const _SwipeToReply({required this.child, this.onSwipe});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  static const double _triggerThreshold = 60;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.onSwipe == null) return;

    setState(() {
      // only allow right swipe
      _dragExtent = (_dragExtent + details.delta.dx).clamp(0.0, 80.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragExtent >= _triggerThreshold && widget.onSwipe != null) {
      widget.onSwipe!();
    }
    setState(() {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onSwipe == null || kIsWeb) {
      return widget.child;
    }

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // reply icon behind
          if (_dragExtent > 10)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Opacity(
                opacity: (_dragExtent / _triggerThreshold).clamp(0.0, 1.0),
                child: Center(
                  child: Icon(
                    Icons.reply_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          // the actual bubble
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
