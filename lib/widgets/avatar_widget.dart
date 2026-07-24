import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/avatar_cache.dart';
import '_web_image_stub.dart'
    if (dart.library.html) '_web_image_web.dart';

/// Renders a user's avatar circle. Tries [imageUrl] first; on any load
/// failure (404, network error, CORS, malformed URL — the cases listed in
/// BUGS_TO_FIX.md "如果无法解析出头像，将头像变成 Label 显示") it transparently
/// falls back to the [label]-based letter avatar so the screen never
/// shows a broken image placeholder.
///
/// Caching strategy is platform-conditional:
/// - Mobile / desktop: route through `cached_network_image`'s
///   `CachedNetworkImage` backed by [AvatarCache.manager] (a dedicated
///   `flutter_cache_manager` `CacheManager`). This gives a single
///   disk-backed fetch per avatar URL, so subsequent screens (member
///   list → chat header → family tree etc.) decode the in-memory
///   copy instead of re-fetching. Replaces the prior raw `Image.network`
///   path which gave us a fresh GET + re-decode per screen entry.
/// - Web: keep the raw `<img>` via `HtmlElementView` (see
///   `_web_image_web.dart`) — the browser's HTTP cache de-dupes by URL
///   anyway, and `package:http`'s `BrowserClient` on web would hit the
///   R2 CORS wall. `CachedNetworkImage` doesn't help here because it
///   still goes through the XHR path.
class AvatarWidget extends StatelessWidget {
  final String label;
  final Color color;
  final String? imageUrl;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.label,
    required this.color,
    this.imageUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: color,
      // Show the full label (1-2 chars — `memberAvatarLabel` may produce
      // "JS" for English names; the previous version unconditionally
      // truncated to 1 char). 2-char labels need a smaller font so they
      // don't overflow the circle.
      child: Text(
        label.isEmpty ? '?' : label,
        style: TextStyle(
          color: Colors.white,
          fontSize: label.length >= 2 ? radius * 0.6 : radius * 0.75,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;
    if (kIsWeb) {
      // Bypass the CORS path that `Image.network` (XHR) and
      // `CachedNetworkImage` (also XHR-based on web) would take.
      return buildPlatformImage(
        url: url,
        size: radius * 2,
        fallback: fallback,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: ClipOval(
        // `CachedNetworkImage` on mobile/desktop pulls bytes from the
        // AvatarCache CacheManager (LruCache in front of a disk store),
        // so the second screen to ask for this avatarURL reads from
        // memory without re-fetching over the network. The disk layer
        // keeps hot avatars warm across cold-launches.
        child: CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheManager: AvatarCache.manager,
          // Treat any error (network/404/malformed) the same as "no
          // avatar available" — fall back to the label circle rather
          // than flashing a broken image. We intentionally do *not*
          // use `loadingBuilder` here: a 200×200 WebP decodes in a
          // single frame on the smallest device we ship for, so the
          // brief gap between "mount" and "decoded" isn't worth a
          // second widget swap.
          errorWidget: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

class GroupAvatarWidget extends StatelessWidget {
  final String label;
  final int memberCount;
  final String? imageUrl;
  final double radius;

  const GroupAvatarWidget({
    super.key,
    required this.label,
    required this.memberCount,
    this.imageUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final Widget avatar;
    if (kIsWeb && imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = buildPlatformImage(
        url: imageUrl!,
        size: radius * 2,
        fallback: fallback,
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Same caching rationale as [AvatarWidget] — group covers also
      // get re-shown on every conversation-tile rebuild, so without a
      // cache the user pays the network round-trip each scroll pass.
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheManager: AvatarCache.manager,
          errorWidget: (_, _, _) => fallback,
        ),
      );
    } else {
      avatar = fallback;
    }
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$memberCount',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
