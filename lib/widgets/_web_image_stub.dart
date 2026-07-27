import 'package:flutter/widgets.dart';

/// Non-web stub for [buildPlatformImage]. The real web implementation
/// (which embeds a raw `<img>` via `HtmlElementView` to bypass
/// Flutter Web's XHR-based CORS path) lives in `_web_image_web.dart` and
/// is selected by the conditional import in `avatar_widget.dart`.
///
/// This stub is only reachable if someone removes the `kIsWeb` guard and
/// calls it on iOS/Android — return the fallback so nothing crashes.
/// The signature must match `_web_image_web.dart` exactly — a conditional
/// import only compiles if both sides expose the same API.
Widget buildPlatformImage({
  required String url,
  required Widget fallback,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  bool circle = false,
  double cornerRadius = 0,
}) =>
    fallback;
