import '../l10n/app_localizations.dart';

/// Providers have no BuildContext to localize with, so local (non-server)
/// error fallbacks are stored as sentinels and localized at the UI layer.
const String kNetworkErrorSentinel = 'NETWORK_ERROR';

/// Maps a raw error string (sentinel or server-provided message) to display
/// text. Server messages (see docs/api.md) aren't further localized here.
String localizeErrorMessage(String raw, AppLocalizations l10n) {
  if (raw == kNetworkErrorSentinel) return l10n.errorNetworkFailed;
  return raw;
}
