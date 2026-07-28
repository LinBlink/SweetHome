import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/app_palette.dart';
import 'package:sweethome_flutter/core/app_theme.dart';

/// Every `TextStyle` the theme hands to a *component* sub-theme has to name the
/// bundled UI font explicitly.
///
/// `ThemeData(fontFamily:)` rewrites only `textTheme` / `primaryTextTheme`;
/// component sub-themes keep the `TextStyle` they were given verbatim, so a
/// style written inline there has `fontFamily == null`. Widgets that install
/// such a style as a `DefaultTextStyle` — [AlertDialog] does exactly this for
/// its title and content — thereby *replace* the ambient style, and everything
/// inside them loses the bundled font.
///
/// That is invisible on mobile (the OS has CJK system fonts) and fatal on web:
/// CanvasKit can't see system fonts, so a style with no registered family
/// covering the codepoint has nothing to draw with, and CJK text renders as
/// nothing at all. The symptom was an empty dialog box on logout / invite-code
/// — title, body and buttons all blank.
///
/// This pins the whole surface rather than the two dialogs that were reported,
/// because the next component theme someone adds is the next blank widget.
void main() {
  const expectedFamily = 'SweetHomeUI';

  void expectBundledFont(TextStyle? style, String what) {
    expect(style, isNotNull, reason: '$what: expected a style to check');
    expect(
      style!.fontFamily,
      expectedFamily,
      reason: '$what has no bundled font — it will render blank on web '
          'CanvasKit for any CJK text. Wrap it in AppTheme._ui().',
    );
    expect(
      style.fontFamilyFallback,
      isNotEmpty,
      reason: '$what has no fallback chain — JP/KR/TC/MY glyphs outside the '
          'Simplified Chinese subset will render blank on web.',
    );
  }

  for (final isDark in [false, true]) {
    group('component sub-theme text styles carry the bundled font '
        '(${isDark ? 'dark' : 'light'})', () {
      final theme = AppTheme.build(AppPalette.terracotta, isDark: isDark);

      test('dialog title + content — the reported blank-dialog case', () {
        expectBundledFont(theme.dialogTheme.titleTextStyle, 'dialogTheme.titleTextStyle');
        expectBundledFont(theme.dialogTheme.contentTextStyle, 'dialogTheme.contentTextStyle');
      });

      test('dialog action buttons', () {
        expectBundledFont(
          theme.textButtonTheme.style?.textStyle?.resolve(<WidgetState>{}),
          'textButtonTheme.style.textStyle',
        );
        expectBundledFont(
          theme.elevatedButtonTheme.style?.textStyle?.resolve(<WidgetState>{}),
          'elevatedButtonTheme.style.textStyle',
        );
      });

      test('app bar title', () {
        expectBundledFont(theme.appBarTheme.titleTextStyle, 'appBarTheme.titleTextStyle');
      });

      test('bottom navigation labels, selected and not', () {
        expectBundledFont(
          theme.navigationBarTheme.labelTextStyle?.resolve(<WidgetState>{WidgetState.selected}),
          'navigationBarTheme.labelTextStyle (selected)',
        );
        expectBundledFont(
          theme.navigationBarTheme.labelTextStyle?.resolve(<WidgetState>{}),
          'navigationBarTheme.labelTextStyle (unselected)',
        );
      });

      test('text field hints', () {
        expectBundledFont(theme.inputDecorationTheme.hintStyle, 'inputDecorationTheme.hintStyle');
      });

      test('snack bar content', () {
        expectBundledFont(theme.snackBarTheme.contentTextStyle, 'snackBarTheme.contentTextStyle');
      });

      test('textTheme still gets it from ThemeData(fontFamily:) itself', () {
        // Not a component sub-theme — this one Flutter does rewrite for us.
        // Here to document the asymmetry that caused the bug.
        expectBundledFont(theme.textTheme.bodyMedium, 'textTheme.bodyMedium');
      });
    });
  }
}
