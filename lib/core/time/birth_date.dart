/// Helpers for the `birthDate` field the API exchanges as a bare ISO-8601
/// calendar date (`YYYY-MM-DD`), plus the derived values the UI shows.
///
/// Age is deliberately computed **on the client**, not sent by the server: it
/// changes on the member's birthday, so a server-computed age baked into a
/// response goes stale the moment the response is cached. The same reasoning
/// the project applies to `relationCode` (see API.md §11.7) — the server sends
/// structured facts, the client derives presentation from them.
library;

/// Formats a date as `YYYY-MM-DD`.
///
/// Deliberately *not* `DateTime.toIso8601String()`, which appends a time
/// component that the backend's `LocalDate` refuses to parse.
String formatApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Parses the API's `YYYY-MM-DD`. Returns null for null/empty/malformed input
/// rather than throwing — a bad date somewhere in a member list should cost
/// that one member's age display, not blow up the whole family tree.
DateTime? parseApiDate(String? s) {
  if (s == null || s.isEmpty) return null;
  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  // Drop any time component so date-only comparisons stay exact.
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Completed years as of [asOf] (defaults to today).
///
/// Counts *completed* years, so someone born on 2000-06-01 is 24 on
/// 2025-05-31 and 25 on 2025-06-01. Returns null when [birthDate] is unknown,
/// and also for future dates — a negative age is never something to render.
int? ageFrom(DateTime? birthDate, {DateTime? asOf}) {
  if (birthDate == null) return null;
  final now = asOf ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (birthDate.isAfter(today)) return null;

  var age = today.year - birthDate.year;
  final hadBirthdayThisYear = today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthdayThisYear) age -= 1;
  return age < 0 ? null : age;
}

/// Whether [birthDate]'s month/day falls on [asOf] (defaults to today).
///
/// Feb 29 birthdays are treated as Mar 1 in non-leap years so they still get
/// their day rather than silently never matching.
bool isBirthdayToday(DateTime? birthDate, {DateTime? asOf}) {
  if (birthDate == null) return false;
  final now = asOf ?? DateTime.now();
  if (birthDate.month == now.month && birthDate.day == now.day) return true;

  final isLeapDayBirthday = birthDate.month == 2 && birthDate.day == 29;
  if (!isLeapDayBirthday) return false;
  final isLeapYear =
      (now.year % 4 == 0 && now.year % 100 != 0) || now.year % 400 == 0;
  return !isLeapYear && now.month == 3 && now.day == 1;
}
