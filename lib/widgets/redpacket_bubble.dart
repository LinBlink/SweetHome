import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_models.dart';
import '../screens/redpacket/redpacket_detail_screen.dart';

/// Inline chat card for `MessageType.redpacket` messages — the §9.1
/// "send a `type=REDPACKET` chat message" payload the sender drops
/// into the conversation after creating the red packet. Tapping
/// navigates to [RedpacketDetailScreen], which fetches the live
/// §9.2/§9.4 state for the actual grab action.
///
/// We intentionally do NOT call `RedpacketService.getById` here:
/// every message bubble shouldn't trigger a network round-trip; the
/// detail screen is where the live grab happens.
class RedpacketBubble extends StatelessWidget {
  final Message message;
  const RedpacketBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        final id = message.redpacketId;
        if (id == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RedpacketDetailScreen(redpacketId: id),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.66,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            // Card stays red/terracotta regardless of `isMe` — a
            // red packet is a red packet. Only the avatar / sender
            // name row above it differs from a normal text bubble.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: const Radius.circular(18),
              bottomRight: const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.redeem_rounded,
                  color: Colors.amber.shade100, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.redpacketCardLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (!message.isMe)
                    Text(
                      l10n.redpacketCardFromLabel(message.senderName),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    )
                  else
                    Text(
                      l10n.redpacketCardLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}