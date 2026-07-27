// Web-only image loader using a raw <img> via HtmlElementView to bypass
// Flutter Web's CORS-enforcing XHR path (see avatar_widget.dart for the
// why). dart:html is deprecated in favor of package:web + dart:js_interop
// but still the shortest path for an ImageElement + onError listener; we
// suppress the lint rather than pull in another dependency.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

/// Renders a network image on Flutter Web by embedding a raw `<img>`
/// element via `HtmlElementView` — bypassing the CORS-enforcing XHR
/// path that `Image.network` uses (Flutter Web's `package:http`
/// `BrowserClient` runs through `XMLHttpRequest`, which the browser
/// blocks for cross-origin responses without `Access-Control-Allow-Origin`
/// headers).
///
/// A plain `<img>` element only enforces CORS when its `crossOrigin`
/// attribute is set, so leaving it unset (this implementation) lets the
/// browser display the image regardless of the server's CORS headers —
/// which is exactly what we want for avatar URLs from Cloudflare R2 when
/// developing locally on `http://localhost:*` / `http://192.168.*:*`
/// against a bucket whose CORS policy doesn't include those origins yet.
///
/// Trade-offs vs. `Image.network`:
/// - No Flutter `ImageCache` (the browser's HTTP cache handles deduping
///   by URL, which is what we actually want here).
/// - No `loadingBuilder` progress — we just show the image (or the
///   [fallback] on error). Fine for avatars, where loading is brief.
class _PlatformImage extends StatefulWidget {
  final String url;
  final Widget fallback;

  /// null => fill whatever the parent lays out for us. Callers that know
  /// their box (avatars, chat bubbles) pass explicit numbers; grid tiles
  /// and lightboxes leave these null so the shape follows the layout.
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shape is the caller's decision, not this widget's — an avatar wants
  /// a circle, a moment tile wants an 8px corner, a lightbox wants
  /// neither. Rounding happens in CSS rather than via an outer
  /// `ClipRRect` because this is a platform view: the browser composites
  /// the `<img>` above Flutter's canvas, where Flutter's own clips don't
  /// reliably reach it.
  final bool circle;
  final double cornerRadius;

  const _PlatformImage({
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.circle = false,
    this.cornerRadius = 0,
  });

  @override
  State<_PlatformImage> createState() => _PlatformImageState();
}

class _PlatformImageState extends State<_PlatformImage> {
  // Each mounted instance gets its own viewType (and therefore its own
  // `<img>` element), so two avatars in the same ListView don't share
  // state. ViewType only needs to be unique within a single
  // platformViewRegistry, hence the static counter.
  static int _nextViewTypeId = 0;
  late final String _viewType;
  bool _errored = false;

  /// Kept so [didUpdateWidget] can repoint an existing `<img>` at a new
  /// URL — the view factory runs once, so its captured `widget.url` goes
  /// stale the moment this widget is recycled onto another image.
  html.ImageElement? _element;

  @override
  void initState() {
    super.initState();
    _viewType = 'web-image-${_nextViewTypeId++}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        // A null width/height becomes CSS `100%`, letting the `<img>`
        // fill the box Flutter hands the HtmlElementView. That's what
        // keeps a grid tile sized by its grid and a lightbox sized by
        // the viewport, instead of by a hardcoded pixel count here.
        final img = html.ImageElement(src: widget.url)
          ..style.width = widget.width == null ? '100%' : '${widget.width}px'
          ..style.height = widget.height == null ? '100%' : '${widget.height}px'
          ..style.objectFit = widget.fit == BoxFit.contain ? 'contain' : 'cover'
          ..style.borderRadius =
              widget.circle ? '50%' : '${widget.cornerRadius}px';
        _element = img;
        img.onError.listen((_) {
          if (mounted) setState(() => _errored = true);
        });
        return img;
      },
    );
  }

  @override
  void didUpdateWidget(_PlatformImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      // The viewType is fixed for this widget instance, so the existing
      // `<img>` stays bound to it — repoint its src by hand and clear any
      // previous error so the new URL gets its own chance to load.
      _element?.src = widget.url;
      setState(() => _errored = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errored) return widget.fallback;
    final view = HtmlElementView(viewType: _viewType);
    // No SizedBox when both are null: it would collapse to zero rather
    // than defer to the parent's constraints.
    if (widget.width == null && widget.height == null) return view;
    return SizedBox(width: widget.width, height: widget.height, child: view);
  }
}

Widget buildPlatformImage({
  required String url,
  required Widget fallback,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  bool circle = false,
  double cornerRadius = 0,
}) {
  return _PlatformImage(
    url: url,
    fallback: fallback,
    width: width,
    height: height,
    fit: fit,
    circle: circle,
    cornerRadius: cornerRadius,
  );
}
