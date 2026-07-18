import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppColors {
  AppColors._();

  // ── Brand: theme-driven (defaults to warm terracotta) ────────────
  /// Backing store for the brand colors below. Defaults to
  /// [AppPalette.terracotta] (matching [ThemeProvider]'s own default)
  /// so anything that reads `AppColors.primary` before the app's
  /// first frame — or from code with no [BuildContext] at all, like
  /// `CustomPainter.paint` or the data layer — still gets a sane
  /// color instead of null/crashing.
  static AppPalette _palette = AppPalette.terracotta;

  /// Called by [ThemeProvider] on restore and on every palette
  /// change. This is what makes theme switching apply globally:
  /// `context.brandPrimary` (via the `AppPalette` `ThemeExtension`)
  /// only reaches widgets that explicitly read it, but the vast
  /// majority of the app reads the static `AppColors.primary` family
  /// directly (per this file's own convention of "reuse an AppColors
  /// constant" instead of hardcoding colors) — including code that
  /// has no `BuildContext` to read a `ThemeExtension` from at all
  /// (`CustomPainter`s, `mock_data.dart`, `avatarColorFor` below).
  /// Routing both through the same [AppPalette] keeps them in sync.
  static void applyPalette(AppPalette palette) {
    _palette = palette;
  }

  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primaryLight => _palette.primaryLight;

  static Color get accent => _palette.accent;

  // ── Dark mode ─────────────────────────────────────────────────────
  /// Backing store for light/dark, mirroring [_palette] above: a
  /// static flag so every `AppColors.xyz` getter — including calls
  /// with no `BuildContext` — reflects the current mode. Set by
  /// [ThemeProvider] on restore, on every explicit mode change, and
  /// whenever the OS brightness flips while following "system".
  static bool _isDark = false;

  static void applyBrightness(bool isDark) {
    _isDark = isDark;
  }

  static bool get isDark => _isDark;

  // ── Surfaces: warm cream paper (light) / warm dark wood (dark) ───
  static Color get background =>
      _isDark ? const Color(0xFF1A1512) : const Color(0xFFFFF8F0);
  static Color get surface =>
      _isDark ? const Color(0xFF242019) : const Color(0xFFFFFAF5);
  static Color get surfaceVariant =>
      _isDark ? const Color(0xFF2E2820) : const Color(0xFFF5EDE3);

  // ── "Wood & linen" — the furniture / shelves the app sits on ─────
  /// Warm wooden tone used for the bottom-nav shelf and app-bar
  /// trim — picks up the same hue family as [primary] but darker
  /// and more saturated, so it reads as "the surface the app is
  /// sitting on" rather than as another button color. Already dark
  /// enough to read the same way against either background, so —
  /// like the brand colors — it deliberately does not change with
  /// light/dark mode.
  static const Color wood = Color(0xFF6E3B1F);
  static const Color woodLight = Color(0xFF8B5A36);

  /// A muted sage that pairs with the terracotta for tag/pill
  /// backgrounds — gives the "kitchen herbs" / "garden" hint that
  /// keeps the warm palette from collapsing into one tone.
  static const Color sage = Color(0xFF7B9E87);
  static Color get sageLight =>
      _isDark ? const Color(0xFF3A4A3E) : const Color(0xFFC9D7C7);

  /// A pale linen / cream used for chip fills, soft-tinted surfaces
  /// on top of [surface]. Slightly warmer than [background] so it
  /// reads as "fabric" rather than "blank paper".
  static Color get linen =>
      _isDark ? const Color(0xFF3D2E1F) : const Color(0xFFFCF1DE);
  static Color get linenDeep =>
      _isDark ? const Color(0xFF4A3826) : const Color(0xFFF3E2C2);

  /// The deep ink of body copy, brown rather than pure black so the
  /// text feels like a fountain-pen on parchment. In dark mode this
  /// flips to a warm off-white so text still reads as "ink" against
  /// the dark paper instead of vanishing into it.
  static Color get ink =>
      _isDark ? const Color(0xFFEDE4D9) : const Color(0xFF3D2B1F);

  /// Soft warm grey for secondary text — the "faded ink" of old
  /// letters, where you can still read it but it isn't shouting.
  static Color get inkFaded =>
      _isDark ? const Color(0xFFB8A890) : const Color(0xFF8B7355);
  static Color get inkFaint =>
      _isDark ? const Color(0xFF8A7860) : const Color(0xFFBBA98A);

  // ── Text — kept as aliases for existing call sites ──────────────
  static Color get textPrimary => ink;
  static Color get textSecondary => inkFaded;
  static Color get textHint => inkFaint;

  // ── Status ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF6B8F71);
  static const Color warning = Color(0xFFF0C040);
  static const Color danger = Color(0xFFC0392B);

  // ── Misc ───────────────────────────────────────────────────────
  static Color get divider =>
      _isDark ? const Color(0xFF3D342A) : const Color(0xFFEDE0D4);
  static Color get shadow =>
      _isDark ? const Color(0x33000000) : const Color(0x1A3D2B1F);

  /// Background colors for the letter-fallback avatars shown to OTHER
  /// family members. Deliberately all cool hues (blue / green / teal /
  /// cyan / indigo / purple / mint / steel) — the previous palette still
  /// had terracotta / amber / rose in it, and even with a 1-of-8 chance
  /// per user, on a 5-member list the eye reads it as "all red" because
  /// every warm tone is in the same neighbourhood. Removing warm hues
  /// entirely is the only way to guarantee the family-members list never
  /// looks monochromatic warm regardless of which hash bucket each
  /// userId lands in.
  ///
  /// The brand terracotta ([primary]) is **not** in this list — it's
  /// reserved for the current user's own avatar (see
  /// [avatarColorFor] when [selfUserId] matches), so a user scanning
  /// the list can spot themselves by the single red badge in a sea of
  /// cool tones.
  static const List<Color> avatarColors = [
    Color(0xFF1E88E5), // Blue 600
    Color(0xFF43A047), // Green 600
    Color(0xFF00897B), // Teal 600
    Color(0xFF00ACC1), // Cyan 600
    Color(0xFF3949AB), // Indigo 600
    Color(0xFF5E35B1), // Deep Purple 600
    Color(0xFF455A64), // Blue Grey 600
    Color(0xFF7B9E87), // Sage
  ];

  /// Stable per-user background for the letter-fallback avatar.
  ///
  /// - If [selfUserId] equals [userId], returns [primary] (terracotta) so
  ///   the current user can spot themselves in a family list that's
  ///   otherwise a palette of cool hues.
  /// - Otherwise picks from [avatarColors] using an XOR-shift hash. The
  ///   previous `userId.hashCode % length` was a no-op for small ints
  ///   (Dart's `int.hashCode` is the int itself), so a 5-member family
  ///   with userIds 1..5 ended up on adjacent indices 1..5 — exactly the
  ///   half of the old palette that read as "red". XOR-shift mixes the
  ///   bits so userIds that share a modulo with [avatarColors.length]
  ///   (e.g. 8, 16, 24, ...) no longer all collapse to the same bucket.
  static Color avatarColorFor(int userId, {int? selfUserId}) {
    if (selfUserId != null && userId == selfUserId) {
      return primary;
    }
    var h = userId;
    h ^= h << 13;
    h ^= h >> 17;
    h ^= h << 5;
    return avatarColors[h.abs() % avatarColors.length];
  }
}
