import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_colors.dart';
import '../core/app_palette.dart';

const String _kPalettePrefKey = 'theme_palette_id';

/// Holds the user's selected [AppPalette]. Survives app restarts
/// (persisted to SharedPreferences under [_kPalettePrefKey]) and
/// logout (the choice is a device-level preference, not a
/// per-account one). One provider per app — created at root, lives
/// the whole authenticated session.
class ThemeProvider extends ChangeNotifier {
  AppPalette _palette = AppPalette.terracotta;
  AppPalette get palette => _palette;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _palette = AppPalette.byId(prefs.getString(_kPalettePrefKey));
    // Keeps `AppColors.primary`/`.primaryDark`/`.primaryLight`/`.accent`
    // (read from all over the app, including code with no BuildContext)
    // in sync with the palette driving `ThemeData` — see
    // `AppColors.applyPalette` for why both need updating together.
    AppColors.applyPalette(_palette);
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
}