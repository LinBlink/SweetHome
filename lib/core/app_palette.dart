import 'package:flutter/material.dart';

/// Theme-aware brand palette. Only the *brand* colors (primary +
/// primaryDark / primaryLight / accent) are exposed here — paper,
/// wood, ink, divider, sage etc. live in [AppColors] and stay
/// constant across themes. The paper / wood envelope is what makes
/// the app feel like a family; the brand color is what gives each
/// theme its identity.
///
/// Registered into [ThemeData] via `extensions: [palette]`, so any
/// widget can read it with:
///
/// ```dart
/// final p = Theme.of(context).extension<AppPalette>()!;
/// ```
///
/// or via the `BrandColors.of(context)` shortcut from
/// `lib/core/brand_colors.dart`.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent;

  /// Stable identifier persisted to SharedPreferences. Lowercase,
  /// ASCII, no spaces — the storage key for the active palette.
  final String id;

  const AppPalette({
    required this.id,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
  });

  // ── Presets ─────────────────────────────────────────────────────

  /// The default "hearth" terracotta. Stays as id `terracotta` so
  /// existing prefs entries keep working across upgrades.
  static const terracotta = AppPalette(
    id: 'terracotta',
    primary: Color(0xFFBF5E3B),
    primaryDark: Color(0xFF8C3A20),
    primaryLight: Color(0xFFE8927A),
    accent: Color(0xFFF4A261),
  );

  static const ocean = AppPalette(
    id: 'ocean',
    primary: Color(0xFF2E7D8F),
    primaryDark: Color(0xFF1C5566),
    primaryLight: Color(0xFF6FAEBE),
    accent: Color(0xFFFFB088),
  );

  static const forest = AppPalette(
    id: 'forest',
    primary: Color(0xFF4D7C5A),
    primaryDark: Color(0xFF2F5A3A),
    primaryLight: Color(0xFF8FB29A),
    accent: Color(0xFFE8C57A),
  );

  static const lavender = AppPalette(
    id: 'lavender',
    primary: Color(0xFF7E5BA6),
    primaryDark: Color(0xFF553778),
    primaryLight: Color(0xFFB79CD4),
    accent: Color(0xFFF4A8C0),
  );

  static const slate = AppPalette(
    id: 'slate',
    primary: Color(0xFF4A5867),
    primaryDark: Color(0xFF2E3946),
    primaryLight: Color(0xFF8898AA),
    accent: Color(0xFFE2B86B),
  );

  static const List<AppPalette> presets = [
    terracotta,
    ocean,
    forest,
    lavender,
    slate,
  ];

  static AppPalette byId(String? id) {
    if (id == null) return terracotta;
    for (final p in presets) {
      if (p.id == id) return p;
    }
    return terracotta;
  }

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? accent,
  }) {
    return AppPalette(
      id: id,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}