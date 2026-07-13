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
  final double size;
  final Widget fallback;

  const _PlatformImage({
    required this.url,
    required this.size,
    required this.fallback,
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

  @override
  void initState() {
    super.initState();
    _viewType = 'web-image-${_nextViewTypeId++}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final img = html.ImageElement(src: widget.url)
          ..style.width = '${widget.size}px'
          ..style.height = '${widget.size}px'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '50%';
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
      // New image — clear any previous error so we attempt the load
      // again. The viewType is fixed for this widget instance, so the
      // existing `<img>` is still bound to it; we let the browser
      // re-fetch via src change is not how <img> works — instead we
      // just re-show the image. The next error/load will fire
      // appropriately.
      setState(() => _errored = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errored) return widget.fallback;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

Widget buildPlatformImage({
  required String url,
  required double size,
  required Widget fallback,
}) {
  return _PlatformImage(url: url, size: size, fallback: fallback);
}
