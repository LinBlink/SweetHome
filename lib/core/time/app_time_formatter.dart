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
  AppTimeFormatter(this.locale, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Locale locale;

  /// Source of "now" for the relative branches (just-now / today /
  /// yesterday / this week). Production uses the wall clock; tests
  /// inject a fixed instant so the assertions don't depend on what
  /// time of day the suite happens to run at — asserting that
  /// "today 14:30" renders as `14:30` silently fails every morning,
  /// because before 14:30 that timestamp is in the *future* and
  /// lands in the "just now" branch instead.
  final DateTime Function() _clock;

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
    final now = _clock();
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
    final now = _clock();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return timeJustNow;
    if (diff.inHours < 1) return timeMinutesAgo(diff.inMinutes);

    // "Today" and "yesterday" are *calendar* questions, so they're answered by
    // comparing calendar days — not by how many 24h blocks have elapsed.
    // `diff.inDays == 1` gets both directions wrong: a message sent yesterday
    // at 20:00 and read today at 09:00 is only 13h old, so it fell through to
    // the bare date instead of "yesterday"; and one sent two days ago at 23:00
    // and read at 00:30 is 25h old, so it claimed "yesterday" when it wasn't.
    final daysApart = _midnight(now).difference(_midnight(local)).inDays;
    if (daysApart == 0) return DateFormat('HH:mm', _bcp47).format(local);
    if (daysApart == 1) return timeYesterday;
    return DateFormat(_isZh ? 'M月d日' : 'MM/dd', _bcp47).format(local);
  }

  /// Local midnight of [d]'s calendar day. Subtracting two of these gives a
  /// whole number of calendar days regardless of the time of day on either
  /// side. Constructed via the local-date constructor rather than by
  /// subtracting a `Duration`, so DST transitions can't shift the boundary.
  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

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