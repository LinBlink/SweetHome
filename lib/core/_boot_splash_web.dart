import 'dart:js_interop';

/// The hand-off out of `web/index.html`'s `#boot-splash`.
///
/// The bootstrap used to drop the splash two `requestAnimationFrame`
/// ticks after `runApp()` resolved, on the assumption that CanvasKit
/// had composited a frame by then. It hadn't — CanvasKit drives its
/// own rendering off rAF too, and nothing orders the two. On Safari
/// the splash faded while the canvas was still blank, so the page
/// showed bare `<body>` background (near-black in dark mode) until the
/// first real frame landed. Chrome happened to win the race, which is
/// why this only ever reproduced on iOS.
///
/// So the decision moved to the only place that actually knows: Dart,
/// from a post-frame callback. `index.html` owns the fade and the
/// idempotence guard; this is just the trigger.
@JS('dismissBootSplash')
external JSFunction? get _dismissFn;

/// Tears down the HTML boot splash. Safe to call more than once, and
/// safe to call when the function is missing (a stale `index.html`
/// from a previous deploy, or a host page that never had a splash) —
/// both are no-ops rather than crashes, because failing to dismiss a
/// splash must never be what breaks the app.
void dismissBootSplash() {
  _dismissFn?.callAsFunction();
}
