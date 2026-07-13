import 'package:flutter/widgets.dart';

/// Non-web stub for [buildPlatformImage]. The real web implementation
/// (which embeds a raw `<img>` via `HtmlElementView` to bypass
/// Flutter Web's XHR-based CORS path) lives in `_web_image_web.dart` and
/// is selected by the conditional import in `avatar_widget.dart`.
///
/// This stub is only reachable if someone removes the `kIsWeb` guard and
/// calls it on iOS/Android — return the fallback so nothing crashes.
Widget buildPlatformImage({
  required String url,
  required double size,
  required Widget fallback,
}) =>
    fallback;
