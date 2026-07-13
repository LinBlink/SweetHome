import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '_web_image_stub.dart'
    if (dart.library.html) '_web_image_web.dart';

/// Renders a user's avatar circle. Tries [imageUrl] first; on any load
/// failure (404, network error, CORS, malformed URL — the cases listed in
/// BUGS_TO_FIX.md "如果无法解析出头像，将头像变成 Label 显示") it transparently
/// falls back to the [label]-based letter avatar so the screen never
/// shows a broken image placeholder.
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
    // Web: route through a raw <img> via HtmlElementView to dodge the
    // CORS path that Image.network (which goes through
    // package:http's BrowserClient / XHR on web) would otherwise hit.
    // Mobile / desktop: Image.network works directly with no CORS
    // equivalent, so keep the previous behavior there.
    if (kIsWeb) {
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
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          // Treat any error (network/404/malformed) and slow loads
          // (>5s) the same as "no avatar available" — fall back to
          // the label circle rather than flashing a broken image.
          errorBuilder: (_, _, _) => fallback,
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : fallback,
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
      avatar = ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : fallback,
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
