import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand: warm terracotta (the "hearth" of the home) ────────────
  static const Color primary = Color(0xFFBF5E3B);
  static const Color primaryDark = Color(0xFF8C3A20);
  static const Color primaryLight = Color(0xFFE8927A);

  static const Color accent = Color(0xFFF4A261);

  // ── Surfaces: warm cream paper ─────────────────────────────────────
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFAF5);
  static const Color surfaceVariant = Color(0xFFF5EDE3);

  // ── "Wood & linen" — the furniture / shelves the app sits on ─────
  /// Warm wooden tone used for the bottom-nav shelf and app-bar
  /// trim — picks up the same hue family as [primary] but darker
  /// and more saturated, so it reads as "the surface the app is
  /// sitting on" rather than as another button color.
  static const Color wood = Color(0xFF6E3B1F);
  static const Color woodLight = Color(0xFF8B5A36);

  /// A muted sage that pairs with the terracotta for tag/pill
  /// backgrounds — gives the "kitchen herbs" / "garden" hint that
  /// keeps the warm palette from collapsing into one tone.
  static const Color sage = Color(0xFF7B9E87);
  static const Color sageLight = Color(0xFFC9D7C7);

  /// A pale linen / cream used for chip fills, soft-tinted surfaces
  /// on top of [surface]. Slightly warmer than [background] so it
  /// reads as "fabric" rather than "blank paper".
  static const Color linen = Color(0xFFFCF1DE);
  static const Color linenDeep = Color(0xFFF3E2C2);

  /// The deep ink of body copy, brown rather than pure black so the
  /// text feels like a fountain-pen on parchment.
  static const Color ink = Color(0xFF3D2B1F);

  /// Soft warm grey for secondary text — the "faded ink" of old
  /// letters, where you can still read it but it isn't shouting.
  static const Color inkFaded = Color(0xFF8B7355);
  static const Color inkFaint = Color(0xFFBBA98A);

  // ── Text — kept as aliases for existing call sites ──────────────
  static const Color textPrimary = ink;
  static const Color textSecondary = inkFaded;
  static const Color textHint = inkFaint;

  // ── Status ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF6B8F71);
  static const Color warning = Color(0xFFF0C040);
  static const Color danger = Color(0xFFC0392B);

  // ── Misc ───────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEDE0D4);
  static const Color shadow = Color(0x1A3D2B1F);

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
