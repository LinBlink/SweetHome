import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../core/time/app_time_formatter.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    String? relationLabel;
    if (relationCode != null) {
      // `relationLabelFor` already resolves the bare spouse code `S`
      // to the correct gendered term (丈夫/妻子) via `targetGender` —
      // same as every other relation, and matching the family tree.
      // It returns `null` (no label) rather than falling back to a
      // generic "配偶" when the gender is unknown.
      //
      // `conversation.otherUserGender` isn't reliably populated by
      // every backend version (some direct conversations come back
      // with it null) — fall back to `AuthProvider.genderForUserId`,
      // which is warmed from the family member roster's `gender`
      // field (always present, unlike `otherUserGender`) by whichever
      // screen last called `loadFamilyMembers()` (see that method's
      // doc comment).
      final targetGender = conversation.otherUserGender ??
          (conversation.otherUserId != null
              ? auth.genderForUserId(conversation.otherUserId!)
              : null);
      relationLabel = relationLabelFor(
        relationCode: relationCode,
        targetGender: targetGender,
        viewerGender: genderFromString(auth.currentUser?.gender),
        appLocale: context.watch<LocaleProvider>().locale,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.05),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(
                            conversation.lastMessageAt,
                            AppLocalizations.of(context)!,
                            Localizations.localeOf(context),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.inkFaint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _LastMessagePreview(
                            conversation: conversation,
                            l10n: l10n,
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

  String _formatTime(DateTime dt, AppLocalizations l10n, Locale locale) {
    final local = dt.toLocal();
    return AppTimeFormatter(locale).forConversationTile(
      local,
      timeJustNow: l10n.timeJustNow,
      timeMinutesAgo: l10n.timeMinutesAgo,
      timeYesterday: l10n.timeYesterday,
    );
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

/// Renders the conversation's last-message preview. For non-text
/// messages the server's `lastMessage` is the raw R2 URL (per
/// docs/api.md §4.1's "服务端只给结构化数据，不做展示层加工" principle),
/// so we render a localized placeholder instead of the URL — the
/// `lastMessageType` field tells us which placeholder to use.
class _LastMessagePreview extends StatelessWidget {
  final Conversation conversation;
  final AppLocalizations l10n;
  const _LastMessagePreview({required this.conversation, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final raw = conversation.lastMessage;
    final IconData? leading;
    final String text;
    switch (conversation.lastMessageType) {
      case MessageType.image:
        leading = Icons.image_outlined;
        text = l10n.chatMessageTypeImage;
        break;
      case MessageType.voice:
        leading = Icons.mic_none_rounded;
        text = l10n.chatMessageTypeVoice;
        break;
      case MessageType.video:
        leading = Icons.videocam_outlined;
        text = l10n.chatMessageTypeVideo;
        break;
      case MessageType.system:
        leading = Icons.info_outline;
        text = l10n.chatMessageTypeSystem;
        break;
      case MessageType.redpacket:
        // §9 — the conversation tile's last-message preview is just
        // a localized "[Red Packet]" placeholder instead of the raw
        // id (the spec's "服务端只给结构化数据，不做展示层加工"
        // principle: show the type, not the id).
        leading = Icons.redeem_rounded;
        text = l10n.chatMessageTypeRedpacket;
        break;
      case MessageType.text:
        leading = null;
        text = raw;
        break;
    }
    if (leading == null) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    return Row(
      children: [
        Icon(leading, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
