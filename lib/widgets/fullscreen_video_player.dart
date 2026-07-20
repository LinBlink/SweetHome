import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/media_cache.dart';

/// Resolves [url] through the same on-disk cache `CachedNetworkImage`
/// uses for photos, then hands `video_player` the local file instead
/// of the raw network URL — without this, `VideoPlayerController.
/// networkUrl` re-streams the clip from the network every time,
/// including after simply closing and reopening the app since
/// nothing persists across process restarts otherwise. Shared by the
/// family feed (`moment_card.dart`) and chat video bubbles
/// (`message_bubble.dart`).
///
/// Skipped on web: `video_player_web` throws `UnimplementedError` for
/// `DataSourceType.file` (there's no filesystem to hand it a `File`
/// from), so web falls back to the original network-streaming path —
/// the browser's own HTTP cache is the best we get there.
Future<VideoPlayerController> cachedVideoController(String url) async {
  if (kIsWeb) {
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
  final file = await MediaCache.videos.getSingleFile(url);
  return VideoPlayerController.file(file);
}

/// Full-screen video playback shell shared by the family-feed's
/// fullscreen video (`moment_card.dart`) and the publish composer's
/// draft preview (`publish_moment_screen.dart`) — same black
/// backdrop, native-aspect-ratio playback, and a translucent
/// play/pause + scrubber + ±10s overlay that auto-hides after three
/// seconds of no interaction. [openController] is supplied by the
/// caller so each site can decide how the `VideoPlayerController` is
/// built (disk-cached network URL for the feed, a local file for an
/// unpublished draft).
class FullscreenVideoPlayer extends StatefulWidget {
  final Future<VideoPlayerController> Function() openController;
  final String loadFailedLabel;

  const FullscreenVideoPlayer({
    super.key,
    required this.openController,
    required this.loadFailedLabel,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = await widget.openController();
      _controller = c;
      await c.initialize();
      await c.setLooping(false);
      c.addListener(_onControllerUpdate);
      if (!mounted) return;
      setState(() => _ready = true);
      // Auto-play on open — the user just asked for fullscreen.
      await c.play();
      _scheduleHide();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if ((_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      setState(() => _showControls = true);
    } else {
      c.play();
      _scheduleHide();
    }
    setState(() {});
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = _controller;
    if (c == null) return;
    final target = c.value.position + delta;
    final clamped =
        target < Duration.zero ? Duration.zero : target > c.value.duration
            ? c.value.duration
            : target;
    await c.seekTo(clamped);
    setState(() {});
    if (!c.value.isPlaying) setState(() => _showControls = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.movie_filter_outlined,
                size: 56,
                color: Colors.white54,
              ),
              const SizedBox(height: 14),
              Text(
                widget.loadFailedLabel,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    final c = _controller;
    if (!_ready || c == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final aspect = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;
    final value = c.value;
    final position = value.position;
    final duration = value.duration;
    final playing = value.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: VideoPlayer(c),
              ),
            ),
            if (value.isBuffering)
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            if (_showControls) ...[
              // top scrim gradient for the close button
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
              // bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _VideoControlsBar(
                  playing: playing,
                  position: position,
                  duration: duration,
                  onPlayPause: _togglePlay,
                  onSeekStart: () => _hideControlsTimer?.cancel(),
                  // `v` already arrives in milliseconds — the Slider's
                  // min/max are set to 0/`duration.inMilliseconds`
                  // below, not a normalized 0–1000 range. Multiplying
                  // by `duration.inMilliseconds` again (the previous
                  // bug) overshot the real duration on almost any
                  // drag, so `seekTo` clamped straight to the end —
                  // "drag once and it jumps to the end".
                  onSeekChange: (v) async {
                    await c.seekTo(Duration(milliseconds: v.toInt()));
                  },
                  onBackward: () => _seekRelative(
                    const Duration(seconds: -10),
                  ),
                  onForward: () => _seekRelative(
                    const Duration(seconds: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact play/pause + scrubber + skip-10s triplet that lives at the
/// bottom of [FullscreenVideoPlayer]. Renders the seek bar via
/// [Slider]; trimming the `value` range so the thumb always lands on
/// a valid millisecond.
class _VideoControlsBar extends StatelessWidget {
  final bool playing;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekStart;
  final ValueChanged<double> onSeekChange;
  final VoidCallback onBackward;
  final VoidCallback onForward;

  const _VideoControlsBar({
    required this.playing,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeekStart,
    required this.onSeekChange,
    required this.onBackward,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              min: 0,
              max: duration.inMilliseconds.toDouble().clamp(1, 1e9),
              value: position.inMilliseconds
                  .toDouble()
                  .clamp(0, duration.inMilliseconds.toDouble()),
              onChangeStart: (_) => onSeekStart(),
              onChanged: onSeekChange,
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: '−10 s',
                onPressed: onBackward,
                icon: const Icon(
                  Icons.replay_10_rounded,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Center(
                  child: IconButton(
                    tooltip: playing ? 'Pause' : 'Play',
                    iconSize: 44,
                    onPressed: onPlayPause,
                    icon: Icon(
                      playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '+10 s',
                onPressed: onForward,
                icon: const Icon(
                  Icons.forward_10_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(position),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _format(duration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
