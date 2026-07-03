import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import 'avatar_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final senderRelationCode = message.senderRelationCode;
    String? senderRelationLabel;
    if (senderRelationCode != null) {
      senderRelationLabel = relationLabelFor(
        relationCode: senderRelationCode,
        targetGender: message.senderGender ?? Gender.male,
        viewerGender: genderFromString(context.watch<AuthProvider>().currentUser?.gender),
        appLocale: context.watch<LocaleProvider>().locale,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AvatarWidget(
              label: message.senderAvatarLabel,
              color: message.senderAvatarColor,
              radius: 18,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      senderRelationLabel != null
                          ? '${message.senderName} · $senderRelationLabel'
                          : message.senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                _BubbleContent(message: message, isMe: isMe),
                Padding(
                  padding: EdgeInsets.only(
                    top: 3,
                    left: isMe ? 0 : 4,
                    right: isMe ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.sentAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                      if (isMe && message.isPending) ...[
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            AvatarWidget(
              label: message.senderAvatarLabel,
              color: AppColors.primary,
              radius: 18,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.day == now.day) return DateFormat('HH:mm').format(local);
    if (now.difference(local).inDays < 7) {
      return DateFormat('E HH:mm').format(local);
    }
    return DateFormat('MM/dd HH:mm').format(local);
  }
}

class _BubbleContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _BubbleContent({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isMe
              ? null
              : Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : AppColors.textPrimary,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
