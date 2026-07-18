import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../core/app_palette.dart';

const String _kPalettePrefKey = 'theme_palette_id';
const String _kThemeModePrefKey = 'theme_mode';

/// Holds the user's selected [AppPalette] and light/dark [ThemeMode].
/// Both survive app restarts (persisted to SharedPreferences) and
/// logout (device-level preferences, not per-account). One provider
/// per app — created at root, lives the whole authenticated session.
///
/// `AppColors`'s color getters are static (no `BuildContext` — they
/// need to work from `CustomPainter`s and the data layer too), so
/// this provider is also the single place that keeps that static
/// state in sync: every palette or brightness change calls
/// `AppColors.applyPalette`/`applyBrightness` before notifying
/// listeners, so by the time widgets rebuild the static getters
/// already reflect the new values.
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppPalette _palette = AppPalette.terracotta;
  ThemeMode _themeMode = ThemeMode.system;

  AppPalette get palette => _palette;
  ThemeMode get themeMode => _themeMode;

  /// Resolves `ThemeMode.system` against the OS's current brightness
  /// — `AppColors` only has one static "is dark" flag, so "system"
  /// has to be collapsed to a concrete light/dark before applying it.
  bool get _effectiveIsDark {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _palette = AppPalette.byId(prefs.getString(_kPalettePrefKey));
    _themeMode = _themeModeFromString(prefs.getString(_kThemeModePrefKey));
    AppColors.applyPalette(_palette);
    AppColors.applyBrightness(_effectiveIsDark);
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Only matters while `themeMode == ThemeMode.system` — the OS
  /// flipped light/dark (or the user changed it in system settings)
  /// while the app was running, so re-resolve and repaint.
  @override
  void didChangePlatformBrightness() {
    if (_themeMode != ThemeMode.system) return;
    AppColors.applyBrightness(_effectiveIsDark);
    notifyListeners();
  }

  Future<void> setPalette(AppPalette palette) async {
    if (palette.id == _palette.id) return;
    _palette = palette;
    AppColors.applyPalette(_palette);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPalettePrefKey, palette.id);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    AppColors.applyBrightness(_effectiveIsDark);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModePrefKey, mode.name);
  }
}

ThemeMode _themeModeFromString(String? s) {
  switch (s) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}
