import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/emoji_only_text.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../core/time/app_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '_web_image_stub.dart'
    if (dart.library.html) '_web_image_web.dart';
import 'avatar_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final senderRelationCode = message.senderRelationCode;
    final locale = Localizations.localeOf(context);
    String? senderRelationLabel;
    if (senderRelationCode != null) {
      senderRelationLabel = relationLabelFor(
        relationCode: senderRelationCode,
        targetGender: message.senderGender,
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
              imageUrl: message.senderAvatarUrl,
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
                      style: TextStyle(
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
                        _formatTime(message.sentAt, locale),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                      if (isMe && message.isPending) ...[
                        const SizedBox(width: 4),
                        SizedBox(
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
              imageUrl: message.senderAvatarUrl,
              radius: 18,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt, Locale locale) {
    final local = dt.toLocal();
    return AppTimeFormatter(locale).forMessageBubble(local);
  }
}

class _BubbleContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _BubbleContent({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Image / voice / system messages use type-specific widgets rather
    // than a plain text bubble. The placeholder text for image / voice /
    // system comes from the localized chatMessageType* keys (see
    // app_*.arb).
    switch (message.type) {
      case MessageType.image:
        return _ImageBubble(
          url: message.content,
          isMe: isMe,
          isPending: message.isPending,
        );
      case MessageType.voice:
      case MessageType.system:
        return _PlaceholderBubble(
          text: switch (message.type) {
            MessageType.voice => l10n.chatMessageTypeVoice,
            MessageType.system => l10n.chatMessageTypeSystem,
            _ => message.content,
          },
          icon: message.type == MessageType.voice
              ? Icons.mic_none_rounded
              : Icons.info_outline,
          isMe: isMe,
        );
      case MessageType.text:
        // Emoji-only messages get a much larger font so the bubble
        // doesn't look like an empty bubble with a tiny pixel — see
        // `emoji_only_text.dart` for the detection heuristic.
        final isEmojiBurst = isEmojiOnlyText(message.content);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isEmojiBurst ? 12 : 14,
              vertical: isEmojiBurst ? 8 : 10,
            ),
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
                fontSize: isEmojiBurst ? 32 : 15,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: isEmojiBurst ? 1.2 : 1.45,
              ),
            ),
          ),
        );
    }
  }
}

/// Inline image bubble. Uses the web-aware `buildPlatformImage` helper
/// to bypass the Flutter Web CORS XHR path the same way
/// `AvatarWidget` does (see _web_image_web.dart). Falls back to a
/// small placeholder when the URL is empty (the optimistic image
/// message right after the user taps "send", before the §2.4 upload
/// completes) or when the image fails to load.
class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  final bool isPending;
  const _ImageBubble({
    required this.url,
    required this.isMe,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _imagePlaceholder(context);
    if (url.isEmpty) return placeholder;
    Widget img;
    if (kIsWeb) {
      img = buildPlatformImage(
        url: url,
        size: 220,
        fallback: placeholder,
      );
    } else {
      img = Image.network(
        url,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (ctx, child, progress) =>
            progress == null ? child : placeholder,
      );
    }
    return GestureDetector(
      onTap: () => _openFullPreview(context),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        child: Stack(
          children: [
            img,
            if (isPending)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: isMe ? Colors.white : AppColors.textHint,
      ),
    );
  }

  void _openFullPreview(BuildContext context) {
    if (url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullImagePreview(url: url),
        fullscreenDialog: true,
      ),
    );
  }
}

class _PlaceholderBubble extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isMe;
  const _PlaceholderBubble({
    required this.text,
    required this.icon,
    required this.isMe,
  });

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
          border: isMe
              ? null
              : Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isMe ? Colors.white70 : AppColors.textHint),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullImagePreview extends StatelessWidget {
  final String url;
  const _FullImagePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (kIsWeb) {
      body = Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: buildPlatformImage(
            url: url,
            size: MediaQuery.of(context).size.width.toDouble(),
            fallback: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
    } else {
      body = Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, size: 64),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: body,
    );
  }
}
