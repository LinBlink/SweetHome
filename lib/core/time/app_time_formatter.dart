import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware + device-timezone-aware date/time formatter for every
/// backend timestamp displayed in the UI.
///
/// All formatter methods expect a `DateTime` already converted via
/// `.toLocal()` — `parseBackendTime()` returns a UTC-anchored instant,
/// and `.toLocal()` shifts it into the device's wall-clock TZ so the
/// pattern below produces the right text for the user.
///
/// The locale passed to the constructor determines the date pattern:
/// - `zh` / `zh_Hans` / `zh_Hant` use CJK-natural shapes
///   (`M月d日` / `M月d日 HH:mm`, which expand to `7月14日` /
///   `7月14日 14:30`) — consistent across Mainland / Hong Kong /
///   Taiwan for this app's family-chat context. intl's built-in
///   `MMMd` symbol drops the `日` suffix once a time field is
///   appended, so the literal pattern is used instead.
/// - All other locales use the Latin numeric shapes (`MM/dd`,
///   `MM/dd HH:mm`).
///
/// The widget tree reads the current locale via
/// `Localizations.localeOf(context)` — passing it in keeps this
/// formatter stateless and easy to unit-test.
class AppTimeFormatter {
  AppTimeFormatter(this.locale);

  final Locale locale;

  bool get _isZh =>
      locale.languageCode == 'zh' ||
      locale.toLanguageTag() == 'zh-Hans' ||
      locale.toLanguageTag() == 'zh-Hant';

  String get _bcp47 => '${locale.languageCode}'
      '${_isZh ? '' : '_${(locale.countryCode ?? '').toUpperCase()}'}';

  /// Chat bubble timestamp: today / this-week / earlier. The
  /// intra-week form (`E HH:mm`) uses `DateFormat.E()` so the day
  /// name is localized (周一 vs Mon vs 月).
  String forMessageBubble(DateTime local) {
    final now = DateTime.now();
    if (local.day == now.day &&
        local.month == now.month &&
        local.year == now.year) {
      return DateFormat('HH:mm', _bcp47).format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat('E HH:mm', _bcp47).format(local);
    }
    return DateFormat(
      _isZh ? 'M月d日 HH:mm' : 'MM/dd HH:mm',
      _bcp47,
    ).format(local);
  }

  /// Conversation list tile: just-now / minutes-ago / today HH:mm /
  /// yesterday / earlier date. The `l10n` strings (`timeJustNow`,
  /// `timeMinutesAgo`, `timeYesterday`) keep "just now" and "Xm ago"
  /// localizable while the formatter handles the date shape.
  String forConversationTile(
    DateTime local, {
    required String timeJustNow,
    required String Function(int minutes) timeMinutesAgo,
    required String timeYesterday,
  }) {
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return timeJustNow;
    if (diff.inHours < 1) return timeMinutesAgo(diff.inMinutes);
    if (local.day == now.day &&
        local.month == now.month &&
        local.year == now.year) {
      return DateFormat('HH:mm', _bcp47).format(local);
    }
    if (diff.inDays == 1) return timeYesterday;
    return DateFormat(_isZh ? 'M月d日' : 'MM/dd', _bcp47).format(local);
  }

  /// Long-form "yyyy-MM-dd HH:mm" used by fence, join-request, alarm
  /// screens. CJK locales get `MMMd HH:mm` for the same shape.
  String forRecordList(DateTime local) => DateFormat(
        _isZh ? 'M月d日 HH:mm' : 'yyyy-MM-dd HH:mm',
        _bcp47,
      ).format(local);

  /// Date-only header for trajectory / history pickers.
  String forDateOnly(DateTime local) =>
      DateFormat(_isZh ? 'M月d日' : 'yyyy-MM-dd', _bcp47).format(local);

  /// Time-only label for trajectory history rows.
  String forTimeOnly(DateTime local) =>
      DateFormat('HH:mm', _bcp47).format(local);
}