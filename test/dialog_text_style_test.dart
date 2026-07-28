import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/app_palette.dart';
import 'package:sweethome_flutter/core/app_theme.dart';

/// The widget-level half of `theme_font_coverage_test.dart`.
///
/// That one checks the `ThemeData` fields; this one pumps a real
/// [AlertDialog] shaped like the logout / invite-code ones and reads the style
/// that actually reaches the `Text` widgets — which is the thing that was
/// broken. [AlertDialog] wraps its title and content in a `DefaultTextStyle`
/// built from `dialogTheme`, *replacing* the ambient style rather than merging
/// with it, so a `dialogTheme` entry without a `fontFamily` silently strips the
/// bundled font from everything in the dialog. On web CanvasKit that means the
/// text has no font to draw with and renders as nothing at all.
void main() {
  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(AppPalette.terracotta, isDark: false),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定要退出当前账号吗？'),
                  actions: [
                    TextButton(onPressed: () {}, child: const Text('取消')),
                    TextButton(onPressed: () {}, child: const Text('确认退出')),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The style a `Text` actually renders with: its own style merged onto the
  /// nearest enclosing `DefaultTextStyle`, exactly as `Text.build` does it.
  TextStyle effectiveStyleOf(WidgetTester tester, String text) {
    final textWidget = tester.widget<Text>(find.text(text));
    final inherited = DefaultTextStyle.of(tester.element(find.text(text)));
    var style = inherited.style;
    if (textWidget.style != null) style = style.merge(textWidget.style);
    return style;
  }

  testWidgets('dialog title, body and buttons all render with the bundled font',
      (tester) async {
    await pumpDialog(tester);

    for (final label in ['退出登录', '确定要退出当前账号吗？', '取消', '确认退出']) {
      final style = effectiveStyleOf(tester, label);
      expect(
        style.fontFamily,
        'SweetHomeUI',
        reason: '"$label" in the dialog resolves to ${style.fontFamily} — with '
            'no bundled family this renders blank on web CanvasKit.',
      );
      expect(style.fontFamilyFallback, isNotEmpty, reason: '"$label" has no fallback chain');
    }
  });
}
