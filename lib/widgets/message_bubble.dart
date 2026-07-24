import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import '../core/app_colors.dart';
import '../core/emoji_only_text.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../core/time/app_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../services/media_cache.dart';
import '_web_image_stub.dart'
    if (dart.library.html) '_web_image_web.dart';
import 'avatar_widget.dart';
import 'fullscreen_video_player.dart';
import 'redpacket_bubble.dart';

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
      case MessageType.video:
        return _VideoBubble(
          url: message.content,
          isMe: isMe,
          isPending: message.isPending,
        );
      case MessageType.voice:
        return _VoiceBubble(
          url: message.content,
          isMe: isMe,
          isPending: message.isPending,
        );
      case MessageType.system:
        return _PlaceholderBubble(
          text: l10n.chatMessageTypeSystem,
          icon: Icons.info_outline,
          isMe: isMe,
        );
      case MessageType.redpacket:
        return RedpacketBubble(message: message);
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

/// Inline video bubble — shows the clip's first frame as a thumbnail
/// with a mini play-button badge. Tapping the badge plays the clip
/// right there in the bubble (muted-free, with sound, toggling
/// play/pause on repeat taps); tapping the rest of the bubble opens
/// the same fullscreen player the family feed uses. Because
/// `ChatRoomScreen` is a normally-pushed route (unlike the family
/// feed's tabs, which `MainShell`'s `PageView` never unmounts just for
/// being scrolled away from), leaving the chat page — popping the
/// route — disposes this widget the ordinary Flutter way, which is
/// enough on its own to stop playback; no extra visibility plumbing
/// needed here the way `_MomentsVideoTileState` needs.
class _VideoBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final bool isPending;
  const _VideoBubble({
    required this.url,
    required this.isMe,
    required this.isPending,
  });

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble>
    with AutomaticKeepAliveClientMixin<_VideoBubble> {
  // In-memory only (not persisted) — shared across every bubble
  // instance in the app so re-scrolling past a video message, or a
  // second message reusing the same URL, doesn't re-extract the same
  // thumbnail. Keyed by URL; unbounded, but chat history is small
  // (§ChatLocalCache caps at 200 messages/conversation) so this never
  // grows large enough to matter.
  static final Map<String, Uint8List> _thumbnailCache = {};

  Uint8List? _thumbnail;

  /// Created lazily on the badge's first tap — most video messages in
  /// a history are never played inline, so eagerly spinning up a
  /// `VideoPlayerController` (and its network/disk fetch) per bubble
  /// the way the thumbnail loads would be wasteful.
  VideoPlayerController? _inlineController;
  bool _inlineLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _VideoBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _thumbnail = null;
      _disposeInlineController();
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    // The chat room screen is a normally-pushed route, not one of
    // `MainShell`'s always-mounted tabs — popping it (leaving the chat
    // page) runs this `dispose()` the ordinary Flutter way, which is
    // all that's needed to stop playback on exit.
    _inlineController?.dispose();
    super.dispose();
  }

  void _disposeInlineController() {
    _inlineController?.dispose();
    _inlineController = null;
  }

  Future<void> _toggleInlinePlay() async {
    if (widget.url.isEmpty || widget.isPending) return;
    var c = _inlineController;
    if (c == null) {
      setState(() => _inlineLoading = true);
      try {
        c = await cachedVideoController(widget.url);
        await c.initialize();
        await c.setLooping(true);
      } catch (_) {
        if (!mounted) return;
        setState(() => _inlineLoading = false);
        return;
      }
      if (!mounted) {
        c.dispose();
        return;
      }
      _inlineController = c;
      setState(() => _inlineLoading = false);
    }
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadThumbnail() async {
    final url = widget.url;
    if (url.isEmpty || kIsWeb) return;
    final cached = _thumbnailCache[url];
    if (cached != null) {
      setState(() => _thumbnail = cached);
      return;
    }
    try {
      // Reuses the same on-disk cache actual playback goes through
      // (`cachedVideoController`) — `video_compress`'s thumbnail
      // extractor only works on a local file, not a network URL, but
      // since the file needs to land on disk before playback anyway,
      // caching it here isn't wasted the way a one-off download
      // purely for a thumbnail would be.
      final file = await MediaCache.videos.getSingleFile(url);
      final bytes = await VideoCompress.getByteThumbnail(
        file.path,
        quality: 60,
        position: 0,
      );
      if (!mounted || bytes == null) return;
      _thumbnailCache[url] = bytes;
      setState(() => _thumbnail = bytes);
    } catch (_) {
      // Leave `_thumbnail` null — the generic movie-icon placeholder
      // in build() covers this case too.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final isMe = widget.isMe;
    final isPending = widget.isPending;
    return GestureDetector(
      onTap: (widget.url.isEmpty || isPending) ? null : () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        child: Container(
          width: 220,
          height: 160,
          color: isMe ? AppColors.primary : AppColors.surfaceVariant,
          alignment: Alignment.center,
          child: isPending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_inlineController?.value.isInitialized ?? false)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _inlineController!.value.size.width,
                          height: _inlineController!.value.size.height,
                          child: VideoPlayer(_inlineController!),
                        ),
                      )
                    else if (_thumbnail != null)
                      Image.memory(_thumbnail!, fit: BoxFit.cover)
                    else
                      Center(
                        child: Icon(
                          Icons.movie_filter_outlined,
                          size: 40,
                          color: isMe ? Colors.white70 : AppColors.textHint,
                        ),
                      ),
                    // A small corner badge instead of a large center
                    // circle — the thumbnail itself is already the
                    // focal point, and a big overlay just covered it
                    // up. Matches the mute-toggle badge already used
                    // on moment feed video tiles
                    // (`_MomentsVideoTileState` in moment_card.dart).
                    // Its own `GestureDetector` wins the tap over the
                    // bubble's outer one (Flutter resolves nested tap
                    // recognizers to the innermost), so tapping the
                    // badge toggles inline play/pause right here while
                    // tapping elsewhere on the bubble still opens the
                    // fullscreen player.
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: (widget.url.isEmpty || isPending)
                            ? null
                            : _toggleInlinePlay,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black45,
                          ),
                          child: _inlineLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  (_inlineController?.value.isPlaying ??
                                          false)
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = widget.url;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FullscreenVideoPlayer(
        openController: () => cachedVideoController(url),
        loadFailedLabel: l10n.momentDetailVideoLoadFailed,
      ),
    ));
  }
}

/// Inline playable voice-message bubble. The player is created lazily
/// on first tap (rather than eagerly per bubble, which would spin up
/// a `just_audio` instance for every voice message in the history) —
/// that same first tap resolves the duration and starts playback.
class _VoiceBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final bool isPending;
  const _VoiceBubble({
    required this.url,
    required this.isMe,
    required this.isPending,
  });

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  AudioPlayer? _player;
  bool _loading = false;
  bool _failed = false;
  Duration? _duration;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.isPending || widget.url.isEmpty) return;
    var player = _player;
    if (player == null) {
      setState(() => _loading = true);
      player = AudioPlayer();
      _player = player;
      try {
        if (kIsWeb) {
          // No local filesystem on web — stream directly and let the
          // browser's own HTTP cache handle repeat plays.
          _duration = await player.setUrl(widget.url);
        } else {
          // Same on-disk cache as chat video bubbles / moment media,
          // via `setFilePath` rather than `LockCachingAudioSource` —
          // the latter proxies through a local cleartext HTTP server
          // that Android blocks by default
          // (`CleartextNotPermittedException`).
          final file = await MediaCache.audio.getSingleFile(widget.url);
          _duration = await player.setFilePath(file.path);
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failed = true;
        });
        return;
      }
      player.playerStateStream.listen((s) {
        if (!mounted) return;
        setState(() {});
      });
      if (!mounted) return;
      setState(() => _loading = false);
    }
    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.play();
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final playing = _player?.playing ?? false;
    final fg = widget.isMe ? Colors.white : AppColors.textPrimary;
    return GestureDetector(
      onTap: _toggle,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.55,
          minWidth: 96,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isMe ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
              bottomRight: Radius.circular(widget.isMe ? 4 : 18),
            ),
            border: widget.isMe
                ? null
                : Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isPending || _loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              else
                Icon(
                  _failed
                      ? Icons.error_outline
                      : playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                  size: 22,
                  color: fg,
                ),
              const SizedBox(width: 8),
              Text(
                _failed
                    ? l10n.momentDetailAudioLoadFailed
                    : _duration != null
                        ? _format(_duration!)
                        : l10n.chatMessageTypeVoice,
                style: TextStyle(fontSize: 14, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
    final size = MediaQuery.of(context).size;
    final placeholder = const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
    );

    final Widget image;
    if (kIsWeb) {
      image = buildPlatformImage(
        url: url,
        size: size.width,
        fallback: placeholder,
      );
    } else {
      image = Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // `InteractiveViewer`'s child must be sized to the viewport
      // (not the image's own intrinsic pixel size) for `BoxFit.contain`
      // to scale the picture up to fill the screen before pinch-zoom
      // even starts — otherwise zooming only magnifies within the
      // image's already-shrunk display size instead of the full
      // screen. Same fix as `_MomentsFullscreenImage` in
      // moment_card.dart.
      body: SizedBox.expand(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 5.0,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: image,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
