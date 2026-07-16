import 'package:flutter/material.dart';

import 'app_palette.dart';

/// `context.brandPrimary` / `context.brandAccent` etc. — short
/// accessors for the active [AppPalette] from the surrounding
/// [ThemeData]. Avoids the verbose
/// `Theme.of(context).extension<AppPalette>()!.primary` call at
/// every read site.
extension BrandColors on BuildContext {
  AppPalette get brand => Theme.of(this).extension<AppPalette>()!;
  Color get brandPrimary => brand.primary;
  Color get brandPrimaryDark => brand.primaryDark;
  Color get brandPrimaryLight => brand.primaryLight;
  Color get brandAccent => brand.accent;
}