import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_icons.dart';

/// Drop-in replacement for [Icon] backed by the custom SVG set.
///
/// Deliberately API-compatible with [Icon] — same `size`, `color`,
/// `semanticLabel` semantics, same [IconTheme] inheritance — so a call
/// site converts by swapping `Icon(Icons.x, ...)` for
/// `AppIcon(AppIcons.x, ...)` and nothing else. That includes honouring
/// the app-wide `iconTheme` in `app_theme.dart` (ink, size 22), so a
/// bare `AppIcon(AppIcons.x)` lands at the same size a bare `Icon` did.
///
/// While the SVG file is still empty this renders the Material icon the
/// spec names as its fallback, at the identical size and colour — so
/// the UI is never broken mid-migration and the difference between a
/// drawn and an undrawn icon is only the artwork.
class AppIcon extends StatelessWidget {
  final AppIconSpec spec;

  /// Edge length in logical pixels. Falls back to `IconTheme.size`,
  /// then to Material's 24.
  final double? size;

  /// Tint. On monochrome artwork this replaces every painted pixel
  /// wholesale. On multicolour artwork the hue is ignored — the drawing
  /// carries its own colours — but the alpha still applies, so the
  /// half-transparent tints the UI uses for dimmed and unselected
  /// states keep working either way. Falls back to `IconTheme.color`.
  final Color? color;

  final String? semanticLabel;

  const AppIcon(
    this.spec, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24.0;

    var resolvedColor = color ?? iconTheme.color ?? const Color(0xFF000000);
    // `IconTheme.opacity` is how disabled states are expressed on
    // Material icons; fold it into the tint so an AppIcon dims the same
    // way an Icon would.
    final opacity = iconTheme.opacity;
    if (opacity != null && opacity < 1.0) {
      resolvedColor = resolvedColor.withValues(
        alpha: resolvedColor.a * opacity,
      );
    }

    // Rebuilds this icon — and only the icons — when the user switches
    // packs in profile settings. Nothing else in the tree has to know.
    return ValueListenableBuilder<AppIconPack>(
      valueListenable: AppIconAssets.pack,
      builder: (_, pack, _) => AppIconArtwork(
        spec,
        pack: pack,
        size: resolvedSize,
        color: resolvedColor,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// One icon from one specific pack, with every ambient input already
/// resolved.
///
/// [AppIcon] is the widget to reach for; this one exists for the pack
/// picker, which has to show packs the user is *not* currently using
/// (and so must not follow `AppIconAssets.pack`).
class AppIconArtwork extends StatelessWidget {
  final AppIconSpec spec;
  final AppIconPack pack;
  final double size;
  final Color color;
  final String? semanticLabel;

  const AppIconArtwork(
    this.spec, {
    super.key,
    required this.pack,
    required this.size,
    required this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppIconAssets.isDrawn(spec, pack)) {
      return Icon(
        spec.fallback,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    final multicolor = AppIconAssets.isMulticolor(spec, pack);

    final picture = SvgPicture.asset(
      spec.assetPathIn(pack),
      width: size,
      height: size,
      colorFilter:
          multicolor ? null : ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      // An icon that fails to parse should leave a hole the size of the
      // icon rather than reflowing the row around it.
      placeholderBuilder: (_) => SizedBox.square(dimension: size),
    );

    // Nothing folded the tint's alpha in for multicolour artwork, since
    // there is no colour filter to fold it into. Applying it here is
    // what keeps the unselected nav items (a 0xCC beige) and disabled
    // rows dimmer than the selected ones.
    if (multicolor && color.a < 1.0) {
      return Opacity(opacity: color.a, child: picture);
    }
    return picture;
  }
}
