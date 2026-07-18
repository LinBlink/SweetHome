import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/locale_provider.dart';

const Map<String, String> kLocaleDisplayNames = {
  'zh-Hans': '简体中文',
  'zh-Hant': '繁體中文',
  'ko': '한국어',
  'my': 'မြန်မာဘာသာ',
  'en': 'English',
  'ja': '日本語',
};

String localeDisplayName(Locale? locale) {
  if (locale == null) return kLocaleDisplayNames['zh-Hans']!;
  return kLocaleDisplayNames[locale.toLanguageTag()] ?? kLocaleDisplayNames['zh-Hans']!;
}

/// Shared bottom sheet for picking one of [kSupportedLocales] — used on both
/// the login screen (pre-auth) and the profile screen (post-auth), so the
/// language choice is never gated behind having an account.
void showLanguagePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: kSupportedLocales.map((locale) {
          return ListTile(
            title: Text(kLocaleDisplayNames[locale.toLanguageTag()] ?? locale.toLanguageTag()),
            onTap: () {
              context.read<LocaleProvider>().setLocale(locale);
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    ),
  );
}

/// Compact "globe + current language" trigger, meant for screens without a
/// settings list (e.g. the pre-auth login screen).
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleProvider>().locale;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showLanguagePickerSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              localeDisplayName(current),
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
