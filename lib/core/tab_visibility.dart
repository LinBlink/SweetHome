import 'package:flutter/widgets.dart';

/// Tells a descendant whether the [MainShell] tab it lives in is the
/// currently selected one. `MainShell`'s `PageView(children: _screens)`
/// keeps every tab mounted off-screen (so scroll position / in-progress
/// state survives a tab switch) rather than tearing pages down like
/// `IndexedStack` with lazy builders would — which means anything that
/// starts its own playback (family-feed inline video/audio tiles) never
/// gets a normal `dispose()` call just from switching tabs and would
/// otherwise keep running invisibly in the background. Widgets that own
/// playback should watch [TabVisibility.of] and pause when it goes
/// false.
class TabVisibility extends InheritedWidget {
  final bool visible;

  const TabVisibility({
    super.key,
    required this.visible,
    required super.child,
  });

  /// Defaults to `true` when there's no ancestor [TabVisibility] (e.g. a
  /// widget under test in isolation, or one reached via a route pushed
  /// outside the tab shell) — visible-by-default matches how these
  /// widgets behaved before this mechanism existed.
  static bool of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<TabVisibility>();
    return widget?.visible ?? true;
  }

  @override
  bool updateShouldNotify(TabVisibility oldWidget) =>
      oldWidget.visible != visible;
}
