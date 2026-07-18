import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/app_colors.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/time/app_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/moment.dart';
import '../providers/moment_provider.dart';
import '../services/media_cache.dart';
import '_web_image_stub.dart' if (dart.library.html) '_web_image_web.dart';
import 'avatar_widget.dart';
import 'fullscreen_video_player.dart';

/// A single row in the family-feed list. Renders the author strip
/// (avatar + name + "liked by" + timestamp), an optional text body,
/// a media grid, and a footer with the like button + like count.
///
/// Tapping the like button delegates to [MomentProvider.toggleLike];
/// tapping an image tile opens a full-screen viewer; video/audio
/// starts inline so a user can scrub a clip without leaving the feed.
class MomentCard extends StatelessWidget {
  final Moment moment;
  final bool isMine;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onTap;

  const MomentCard({
    super.key,
    required this.moment,
    required this.isMine,
    this.onDeleteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final time = AppTimeFormatter(locale)
        .forRecordList(moment.createdAt.toLocal());
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(
              moment: moment,
              timeText: time,
              isMine: isMine,
              onDeleteTap: onDeleteTap,
            ),
            if (moment.content != null && moment.content!.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                moment.content!,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
            if (moment.media.isNotEmpty) ...[
              const SizedBox(height: 10),
              _MediaGrid(media: moment.media),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LikeRow(momentId: moment.id),
                const SizedBox(width: 16),
                Expanded(
                  child: _CommentPreview(momentId: moment.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final Moment moment;
  final String timeText;
  final bool isMine;
  final VoidCallback? onDeleteTap;

  const _AuthorRow({
    required this.moment,
    required this.timeText,
    required this.isMine,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AvatarWidget(
          label: memberAvatarLabel(moment.username),
          color: AppColors.avatarColorFor(moment.userId),
          imageUrl: moment.userAvatarUrl,
          radius: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                moment.username,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        if (isMine)
          IconButton(
            tooltip: l10n.familyFeedDeleteTitle,
            onPressed: onDeleteTap,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.textHint,
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _LikeRow extends StatelessWidget {
  final int momentId;
  const _LikeRow({required this.momentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MomentProvider>();
    final count = provider.likeCountOf(momentId);
    final mineActive = provider.hasMyLike(momentId);
    final color = likeHeartColor(count);
    final filled = count > 0;
    final iconData = filled
        ? Icons.favorite_rounded
        : Icons.favorite_border_rounded;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          tooltip: mineActive
              ? l10n.familyFeedLikeTooltipLong
              : l10n.familyFeedLikeTooltip,
          onPressed: () {
            HapticFeedback.selectionClick();
            provider.addLike(momentId);
          },
          onLongPress: mineActive
              ? () => _onLongPress(context, provider, l10n)
              : null,
          icon: Icon(iconData, color: color, size: 22),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        Text(
          count == 0
              ? ''
              : l10n.familyFeedLikeCount(count),
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _onLongPress(
    BuildContext context,
    MomentProvider provider,
    AppLocalizations l10n,
  ) async {
    HapticFeedback.heavyImpact();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.cancelLike(momentId);
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            localizeErrorMessage(e.message, l10n),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.familyFeedLikeCancelFailed)),
      );
    }
  }
}

/// Bottom-right footer preview: comment count + the most recent
/// comment's author/content, so a glance at the card tells you
/// there's a live conversation without opening the detail screen.
/// Backfilled per-moment by `MomentProvider._backfillComments`
/// (mirrors the like-count backfill — §7.2's feed list carries no
/// comment data). Hidden entirely until at least one comment exists.
class _CommentPreview extends StatelessWidget {
  final int momentId;
  const _CommentPreview({required this.momentId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MomentProvider>();
    final count = provider.commentCountOf(momentId);
    final latest = provider.latestCommentOf(momentId);
    if (count == 0 || latest == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          Icons.mode_comment_outlined,
          size: 13,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${l10n.momentCardCommentCount(count)} · '
            '${l10n.momentCardLatestComment(latest.content)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }
}

/// Heart color stops by [count]. Steps chosen so a single family
/// member gives a soft warm hint and a packed thread reads as a
/// deep red — the gradient matches the family's brand primary at the
/// low end and reserves saturated red for "this moment got real love".
Color likeHeartColor(int count) {
  if (count <= 0) return AppColors.textHint;
  if (count == 1) return AppColors.primary;
  if (count <= 4) return AppColors.accent;
  if (count <= 9) return Colors.red.shade500;
  if (count <= 29) return Colors.red.shade700;
  return Colors.pink.shade400;
}

/// Up to 9 media tiles in a 1/3 grid. Single-media moments get one
/// full-width row; 2/4 get 2-col; 3/6/9 get 3-col; 5/7/8 fall back
/// to 3-col with a "more" overlay on overflow (we keep the spec's
/// 9-item cap as the editor's responsibility, so we don't try to
/// guard at the renderer layer).
class _MediaGrid extends StatelessWidget {
  final List<MomentMedia> media;
  const _MediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    if (media.length == 1) {
      return _MediaTile(media: media.first, aspectRatio: 4 / 3);
    }
    final cols = media.length == 2 || media.length == 4 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: media.length,
      itemBuilder: (ctx, i) => _MediaTile(media: media[i], aspectRatio: 1),
    );
  }
}

/// One tile in the media grid. Renders inline for audio (just_audio)
/// and video (video_player),[image tiles fall through to the
/// network image with tap-to-lightbox.
class _MediaTile extends StatelessWidget {
  final MomentMedia media;
  final double aspectRatio;
  const _MediaTile({required this.media, this.aspectRatio = 1});

  @override
  Widget build(BuildContext context) {
    switch (media.type) {
      case MomentMediaType.image:
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: _MomentsImageTile(url: media.url),
        );
      case MomentMediaType.video:
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: _MomentsVideoTile(url: media.url),
        );
      case MomentMediaType.audio:
        return _MomentsAudioTile(url: media.url);
    }
  }
}

class _MomentsImageTile extends StatelessWidget {
  final String url;
  const _MomentsImageTile({required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        size: 32,
        color: AppColors.textHint,
      ),
    );
    Widget img;
    if (kIsWeb) {
      img = buildPlatformImage(
        url: url,
        size: 600,
        fallback: placeholder,
      );
    } else {
      // Disk-cached via `cached_network_image` so re-scrolling the feed,
      // reopening the detail screen, or relaunching the app doesn't
      // redownload media that's already been viewed once.
      img = CachedNetworkImage(
        imageUrl: url,
        cacheManager: MediaCache.images,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _MomentsFullscreenImage(url: url),
          ),
        ),
        child: img,
      ),
    );
  }
}

/// Resolves [url] through the same on-disk cache `CachedNetworkImage`
/// uses for photos, then hands `video_player` the local file instead of
/// the raw network URL. Without this, `VideoPlayerController.networkUrl`
/// re-streams the clip from the network every time — including after
/// simply closing and reopening the app, since nothing persists across
/// process restarts otherwise.
///
/// Skipped on web: `video_player_web` throws `UnimplementedError` for
/// `DataSourceType.file` (there's no filesystem to hand it a `File`
/// from), so web falls back to the original network-streaming path —
/// the browser's own HTTP cache is the best we get there.
Future<VideoPlayerController> _cachedVideoController(String url) async {
  if (kIsWeb) {
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
  final file = await MediaCache.videos.getSingleFile(url);
  return VideoPlayerController.file(file);
}

/// Silent autoplay inline video preview — muted + looping as soon as
/// it's ready, matching the muted-autoplay convention of most social
/// feeds (WeChat Moments / Douyin) instead of a frozen first frame
/// requiring a tap just to see it move. Tapping opens the fullscreen
/// player, which restarts the clip from the beginning with sound.
/// Initializes a single `VideoPlayerController` per URL — same URL
/// twice in the feed would currently spawn two controllers;
/// acceptable for a family feed (where the same moment isn't
/// on-screen twice) and avoids the manager indirection overhead.
class _MomentsVideoTile extends StatefulWidget {
  final String url;
  const _MomentsVideoTile({required this.url});

  @override
  State<_MomentsVideoTile> createState() => _MomentsVideoTileState();
}

class _MomentsVideoTileState extends State<_MomentsVideoTile>
    with AutomaticKeepAliveClientMixin<_MomentsVideoTile> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _muted = true;

  // Keeps this tile's state (and its `VideoPlayerController`) alive when
  // `ListView.builder` scrolls it out of the cache extent — without this,
  // the element gets disposed and re-created on every scroll-back, which
  // tears down the controller and re-fetches the video from the network
  // from scratch each time.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = await _cachedVideoController(widget.url);
      _controller = c;
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(true);
      if (!mounted) return;
      setState(() => _initialized = true);
      await c.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null) return;
    final nextMuted = !_muted;
    await c.setVolume(nextMuted ? 0 : 1);
    if (!mounted) return;
    setState(() => _muted = nextMuted);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    if (_failed) {
      return _failedTile(l10n.momentDetailVideoLoadFailed);
    }
    final c = _controller;
    // Fills the tile via BoxFit.cover (like the image tiles) instead of
    // an inner AspectRatio, which used to pillarbox portrait ("tall")
    // videos against the Stack's bottomLeft alignment — the video's
    // right edge landed mid-tile with a hard, unrounded cut instead of
    // reaching the ClipRRect'd corner.
    final thumbnail = _initialized && c != null
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          )
        : Container(
            color: AppColors.surfaceVariant,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _MomentsFullscreenVideo(url: widget.url),
          ));
        },
        child: Stack(
          children: [
            Positioned.fill(child: thumbnail),
            // Mute toggle — tapping plays the inline preview with sound
            // in place, without leaving the feed. Its own GestureDetector
            // wins the tap over the tile's (Flutter resolves nested tap
            // recognizers to the innermost one), same pattern as the
            // delete IconButton inside MomentCard's own InkWell.
            Positioned(
              left: 6,
              bottom: 6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black45,
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failedTile(String msg) => Container(
        color: AppColors.surfaceVariant,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_outlined,
              size: 28,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 4),
            Text(
              msg,
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      );
}

/// Inline audio clip with play/pause + scrubber. Uses `just_audio`
/// which supports opussy HTTP streaming across all platforms. The
/// controller is created once on first build and reused — multiple
/// cards with the same URL each get their own controller instance,
/// which keeps the UI thread safe even when the feed scrolls
/// quickly past dozens of audio tiles.
class _MomentsAudioTile extends StatefulWidget {
  final String url;
  const _MomentsAudioTile({required this.url});

  @override
  State<_MomentsAudioTile> createState() => _MomentsAudioTileState();
}

class _MomentsAudioTileState extends State<_MomentsAudioTile>
    with AutomaticKeepAliveClientMixin<_MomentsAudioTile> {
  AudioPlayer? _player;
  Duration? _duration;
  Duration _position = Duration.zero;
  bool _ready = false;
  bool _failed = false;

  // Same rationale as `_MomentsVideoTileState.wantKeepAlive`: without
  // this, scrolling the clip off/on screen tears down and re-fetches
  // the audio stream on every scroll-back.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = AudioPlayer();
    _player = p;
    try {
      if (kIsWeb) {
        // No local filesystem on web — stream directly and let the
        // browser's own HTTP cache handle repeat plays.
        _duration = await p.setUrl(widget.url);
      } else {
        // Same on-disk cache as the video tile (`_cachedVideoController`)
        // and photos (`CachedNetworkImage`), then play the local file.
        // Deliberately not `LockCachingAudioSource`: on Android it plays
        // through a local cleartext HTTP proxy on 127.0.0.1, which the
        // OS blocks by default (`CleartextNotPermittedException`) unless
        // the app ships a network-security-config carving out an
        // exception — this sidesteps that entirely by never touching
        // ExoPlayer's network layer for the cached path.
        final file = await MediaCache.audio.getSingleFile(widget.url);
        _duration = await p.setFilePath(file.path);
      }
      p.positionStream.listen((d) {
        if (!mounted) return;
        setState(() => _position = d);
      });
      p.playerStateStream.listen((s) {
        if (!mounted) return;
        if (s.processingState == ProcessingState.completed) {
          setState(() => _position = Duration.zero);
        }
      });
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e, st) {
      debugPrint('Moments audio load failed for ${widget.url}: $e\n$st');
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    if (_failed) {
      return _failedTile(l10n.momentDetailAudioLoadFailed);
    }
    if (!_ready || _player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.linen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('…',
                style: TextStyle(color: AppColors.textHint, fontSize: 14)),
          ],
        ),
      );
    }
    final playing = _player!.playing;
    final dur = _duration ?? Duration.zero;
    final pos = _position;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.linen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: playing ? l10n.momentDetailAudioPause : l10n.momentDetailAudioPlay,
            onPressed: () {
              if (playing) {
                _player!.pause();
              } else {
                _player!.play();
              }
              setState(() {});
            },
            icon: Icon(
              playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              size: 32,
              color: AppColors.primary,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceVariant,
                    thumbColor: AppColors.primary,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: pos.inMilliseconds
                        .toDouble()
                        .clamp(0, dur.inMilliseconds.toDouble()),
                    min: 0,
                    max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: (v) {
                      _player!.seek(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(pos),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      _format(dur),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _failedTile(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.linen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.mic_none_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      );

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Full-screen image lightbox. The image is laid out against the
/// full screen via [SizedBox.expand] so [BoxFit.contain] computes
/// against the viewport (instead of the image's natural pixel size,
/// which previously left the picture unscaled and pushed it to one
/// corner instead of centering it). [InteractiveViewer] then owns
/// the pinch-zoom + pan; a translucent tap layer on top dismisses
/// the lightbox when the user wants to return to the feed.
class _MomentsFullscreenImage extends StatelessWidget {
  final String url;
  const _MomentsFullscreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final Widget image;
    if (kIsWeb) {
      image = buildPlatformImage(
        url: url,
        size: size.width,
        fallback: const Center(
          child: Icon(Icons.broken_image_outlined, size: 64),
        ),
      );
    } else {
      // Same disk cache as the feed tile (`CachedNetworkImage` keys on
      // URL), so opening the lightbox for an already-seen image is
      // instant instead of a second network fetch.
      image = CachedNetworkImage(
        imageUrl: url,
        cacheManager: MediaCache.images,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
        errorWidget: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 64),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: SizedBox.expand(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                clipBehavior: Clip.hardEdge,
                panEnabled: true,
                scaleEnabled: true,
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
          ),
        ],
      ),
    );
  }
}

/// Full-screen video player pushed when a user taps an inline
/// `_MomentsVideoTile`. Thin wrapper over the shared
/// [FullscreenVideoPlayer] shell (also used by the publish
/// composer's draft preview) — this site's only job is supplying how
/// to open the controller (the disk-cached network URL) and the
/// localized failure label.
class _MomentsFullscreenVideo extends StatelessWidget {
  final String url;
  const _MomentsFullscreenVideo({required this.url});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FullscreenVideoPlayer(
      openController: () => _cachedVideoController(url),
      loadFailedLabel: l10n.momentDetailVideoLoadFailed,
    );
  }
}
