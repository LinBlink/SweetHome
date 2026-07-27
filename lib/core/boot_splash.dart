/// Dismisses the HTML boot splash that `web/index.html` paints before
/// Flutter exists. No-op off the web.
///
/// Call it from a post-frame callback, never from `build` — the point
/// is to signal "a frame is actually on screen", and `build` runs
/// before that is true.
library;

export '_boot_splash_stub.dart' if (dart.library.html) '_boot_splash_web.dart';
