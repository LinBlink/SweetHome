import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  /// Family names from `pubspec.yaml`'s `fonts:` section. Built by
  /// `scripts/build_ui_fonts.py`; rerun it after editing any ARB file
  /// so newly introduced characters stay covered offline.
  static const String uiFontFamily = 'SweetHomeUI';
  static const List<String> uiFontFallback = <String>[
    'SweetHomeUI TC',
    'SweetHomeUI JP',
    'SweetHomeUI KR',
    'SweetHomeUI MY',
    // Symbol blocks (arrows, math, misc technical incl. ⏰/⏳,
    // something-typed dingbats). The CJK subsets above ask for these
    // codepoints but their source fonts have no glyphs there, so without
    // these two at the end of the chain CanvasKit goes to the network
    // for a "≥" or a "→" — cheap now that the fallback mirror answers,
    // but still a round trip and a re-layout for characters this common.
    // Symbols before Symbols 2 because Symbols has the
    // narrower arrows/misc-tech coverage, and the most commonly
    // triggered fetch was Noto Sans Symbols (v1).
    'SweetHomeUI Symbols',
    'SweetHomeUI Symbols 2',
    // No emoji family. Nothing here covers emoji, so they resolve
    // through the engine's own fallback — which we mirror in full at
    // `/gfonts/` (scripts/fetch_gfonts_mirror.py), giving complete
    // Noto Color Emoji instead of the subset we used to bundle. See
    // pubspec.yaml's `fonts:` section for the trade.
  ];

  /// [uiFontFamily] followed by [uiFontFallback] — the whole chain as one
  /// list, for the rare style that has to name a different family first
  /// (the `monospace` debug surfaces) and still wants the bundled coverage
  /// behind it.
  static const List<String> uiFontChain = <String>[
    uiFontFamily,
    ...uiFontFallback,
  ];

  /// Stamps the bundled UI font onto a component sub-theme's [TextStyle].
  ///
  /// **This is not optional, and it is not cosmetic.** `ThemeData(fontFamily:)`
  /// only rewrites `textTheme` / `primaryTextTheme`; every `TextStyle` handed
  /// to a component sub-theme (`dialogTheme.titleTextStyle`,
  /// `appBarTheme.titleTextStyle`, a button theme's `textStyle`, …) is stored
  /// verbatim, with `fontFamily == null`. Widgets like [AlertDialog] then
  /// install that style as a `DefaultTextStyle` that *replaces* the ambient
  /// one, so the bundled font is gone for everything inside them.
  ///
  /// On mobile that's invisible — the OS has CJK system fonts to fall back on.
  /// On web it is not: CanvasKit cannot see system fonts, so a style with no
  /// registered family covering the codepoint has nothing to draw with. It
  /// tries fonts.gstatic.com mid-render, and when that fetch fails (offline,
  /// or behind the GFW) the text renders as *nothing* — which is why dialogs
  /// came up as an empty rounded rectangle: title, body and buttons all blank.
  ///
  /// The same stamp is needed by any `TextStyle` handed to a bare
  /// [TextPainter], for a different and noisier failure — see [ui].
  static TextStyle _ui(TextStyle style) => ui(style);

  /// Public form of [_ui], for styles that never pass through a `Text`
  /// widget: anything measured or painted by a bare [TextPainter].
  ///
  /// A `Text` merges its style onto the ambient `DefaultTextStyle`, so a
  /// font-less `TextStyle(fontSize: 12)` still inherits the bundled family
  /// and renders correctly. A [TextPainter] has no ambient anything — it
  /// lays out the style exactly as given, with **no font family at all**.
  ///
  /// On mobile that is harmless. On web it is a request storm. CanvasKit
  /// checks each paragraph's codepoints against *only the families that
  /// paragraph names*; with none named, every codepoint above U+009F counts
  /// as missing, and the engine goes off to `fontFallbackBaseUrl` for a Noto
  /// font to cover it. We serve 404 there on purpose (the app bundles what
  /// it needs — see `web/flutter_bootstrap.js`), and the engine does not
  /// remember a failed download: it re-queues the same font the next time
  /// that text is laid out. Worse, finishing a batch — even an all-failed
  /// one — broadcasts a font-change message that re-lays out every paragraph
  /// in the app, which walks straight back into the same missing codepoint.
  /// One font-less [TextPainter] on screen is therefore a permanent loop of
  /// 404s, at animation frame rate if the painter sits in an animated build.
  ///
  /// Nothing looks wrong while it happens, which is what makes it worth a
  /// guard: the visible `Text` next to the painter renders fine, because
  /// *it* inherited the family.
  static TextStyle ui(TextStyle style) => style.copyWith(
        fontFamily: uiFontFamily,
        fontFamilyFallback: uiFontFallback,
      );

  /// The "过家家 · Sweet Home" theme.
  ///
  /// [palette] drives the brand identity (primary / primaryDark /
  /// primaryLight / accent); [isDark] drives light/dark mode via
  /// `AppColors`'s brightness-aware getters (paper/ink/divider flip,
  /// wood/sage/status colors deliberately stay constant — see
  /// `AppColors` for which is which). The palette is registered into
  /// the resulting [ThemeData] via `extensions:` so widgets can
  /// read it with `Theme.of(context).extension<AppPalette>()!`
  /// (or the `BrandColors.of(context)` shortcut).
  static ThemeData build(AppPalette palette, {required bool isDark}) {
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: Colors.white,
            primaryContainer: palette.primaryLight,
            onPrimaryContainer: palette.primaryDark,
            secondary: palette.accent,
            onSecondary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.ink,
            surfaceContainerHighest: AppColors.surfaceVariant,
            error: AppColors.danger,
            outline: AppColors.divider,
            surfaceTint: AppColors.surface,
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: Colors.white,
            primaryContainer: palette.primaryLight,
            onPrimaryContainer: palette.primaryDark,
            secondary: palette.accent,
            onSecondary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.ink,
            surfaceContainerHighest: AppColors.surfaceVariant,
            error: AppColors.danger,
            outline: AppColors.divider,
            surfaceTint: AppColors.surface,
          );
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      // Bundled subsets, declared in pubspec.yaml. Without these the
      // web build has no font covering CJK and CanvasKit fetches one
      // from fonts.gstatic.com per script, mid-render — a round trip
      // on first paint everywhere, and tofu boxes behind the GFW.
      // Simplified Chinese leads because it's the default locale; the
      // rest chain after it so a mixed-script screen still resolves.
      fontFamily: uiFontFamily,
      fontFamilyFallback: uiFontFallback,
      extensions: <ThemeExtension<dynamic>>[palette],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _ui(TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: 0.4,
        )),
        iconTheme: IconThemeData(color: AppColors.ink),
        actionsIconTheme: IconThemeData(color: AppColors.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.wood,
        indicatorColor: palette.primaryLight.withValues(alpha: 0.4),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: Color(0xCCEFE0D0));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _ui(const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ));
          }
          return _ui(const TextStyle(
            color: Color(0xCCEFE0D0),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ));
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: palette.primary.withValues(alpha: 0.10),
            width: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: _ui(TextStyle(color: AppColors.textHint)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: _ui(const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          )),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: _ui(const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          )),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: BorderSide(color: palette.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: palette.primary.withValues(alpha: 0.10),
            width: 0.8,
          ),
        ),
        titleTextStyle: _ui(TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        )),
        contentTextStyle: _ui(TextStyle(
          fontSize: 14,
          color: AppColors.ink,
          height: 1.4,
        )),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.wood,
        contentTextStyle: _ui(const TextStyle(
          color: Colors.white,
          fontSize: 14,
        )),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return Colors.white;
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return palette.primary;
          return AppColors.divider;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(color: palette.primary.withValues(alpha: 0.6), width: 1.4),
        fillColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return palette.primary;
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: AppColors.linenDeep,
        circularTrackColor: AppColors.linenDeep,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 0.6,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: AppColors.ink,
        size: 22,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, height: 1.4),
        bodyMedium: TextStyle(color: AppColors.ink, height: 1.4),
        bodySmall: TextStyle(color: AppColors.inkFaded, height: 1.4),
        labelLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(color: AppColors.inkFaded),
        labelSmall: TextStyle(color: AppColors.inkFaded, letterSpacing: 0.4),
      ),
    );
  }
}
