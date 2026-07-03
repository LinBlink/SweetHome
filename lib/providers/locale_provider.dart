import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocalePrefKey = 'locale';

/// Supported app locales — keep in sync with lib/l10n/*.arb and
/// lib/core/kinship/terms/*.dart. ARB locale suffixes (zh_Hans/zh_Hant) map
/// to Flutter's script subtag, so these MUST use `Locale.fromSubtags` with
/// `scriptCode:` (not the `Locale(languageCode, countryCode)` constructor) —
/// the generated `AppLocalizations` lookup switches on `locale.scriptCode`.
final List<Locale> kSupportedLocales = [
  const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  const Locale('ko'),
  const Locale('my'),
  const Locale('en'),
  const Locale('ja'),
];

/// Persists the user's chosen app language, independent of `AuthProvider`'s
/// session storage (own SharedPreferences key, survives logout).
class LocaleProvider extends ChangeNotifier {
  // Always non-null once constructed, so MaterialApp.locale never falls back
  // to Flutter's implicit system-locale resolution — the language-picker
  // badge (which defaults its label to zh_Hans) would otherwise disagree
  // with whatever language the browser/OS negotiated for actual page content.
  Locale _locale = kSupportedLocales.first;
  Locale get locale => _locale;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final tag = prefs.getString(_kLocalePrefKey);
    if (tag == null) return;
    final match = kSupportedLocales.where((l) => l.toLanguageTag() == tag);
    if (match.isNotEmpty) {
      _locale = match.first;
      Intl.defaultLocale = _locale.toString();
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    Intl.defaultLocale = locale.toString();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalePrefKey, locale.toLanguageTag());
  }
}
