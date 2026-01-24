import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkest/app/theme/text_styles.dart';
import 'package:talkest/features/auth/models/app_user.dart';
import 'package:talkest/features/chat/models/chat.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final AppUser otherUser;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.otherUser,
    required this.currentUserId,
    required this.onTap,
  });

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('dd/MM/yy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = chat.unreadCount[currentUserId] ?? 0;
    final hasUnread = unreadCount > 0;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: otherUser.photoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: otherUser.photoUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.outline,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => CircleAvatar(
                  radius: 24,
                  child: Text(
                    otherUser.displayName.isNotEmpty
                        ? otherUser.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              height: 48,
              width: 48,
              child: CircleAvatar(
                radius: 24,
                child: Text(
                  otherUser.displayName.isNotEmpty
                      ? otherUser.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
      title: Text(
        otherUser.displayName,
        style: AppTextStyles.titleSmall.copyWith(
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              chat.lastMessage!.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
              ),
            )
          : Text(""),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessage != null)
            Text(
              _formatTimestamp(chat.lastMessage!.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            SizedBox(child: Text("")),
          ],
        ],
      ),
    );
  }
}
