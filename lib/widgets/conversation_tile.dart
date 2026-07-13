import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import 'avatar_widget.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final relationCode = conversation.relationCode;
    String? relationLabel;
    if (relationCode != null) {
      relationLabel = relationLabelFor(
        relationCode: relationCode,
        targetGender: conversation.otherUserGender,
        viewerGender: genderFromString(context.watch<AuthProvider>().currentUser?.gender),
        appLocale: context.watch<LocaleProvider>().locale,
      );
    }
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          relationLabel != null
                              ? '${conversation.name} · $relationLabel'
                              : conversation.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(conversation.lastMessageAt, AppLocalizations.of(context)!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: conversation.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (conversation.isGroup) {
      return GroupAvatarWidget(
        label: conversation.avatarLabel,
        memberCount: conversation.memberCount,
        imageUrl: conversation.avatarUrl,
        radius: 26,
      );
    }
    final avatar = AvatarWidget(
      label: conversation.avatarLabel,
      color: conversation.avatarColor,
      imageUrl: conversation.avatarUrl,
      radius: 26,
    );
    final otherUserId = conversation.otherUserId;
    if (otherUserId == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Selector<ChatProvider, bool>(
            selector: (_, chat) => chat.isUserOnline(otherUserId),
            builder: (_, isOnline, _) => isOnline ? const _OnlineDot() : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt, AppLocalizations l10n) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
    if (local.day == now.day) return DateFormat('HH:mm').format(local);
    if (diff.inDays == 1) return l10n.timeYesterday;
    return DateFormat('MM/dd').format(local);
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
