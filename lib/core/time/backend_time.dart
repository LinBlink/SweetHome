/// Backend contract: every timestamp returned by the API comes back
/// as ISO-8601 WITHOUT a timezone suffix (e.g. `"2026-07-14T16:00:00"`).
/// The values are stored and emitted in **UTC+8 (Asia/Shanghai)**
/// wall-clock time — the backend serializes naive `LocalDateTime` /
/// `Instant.toString()` values from a JVM running in the +08:00 zone.
///
/// Dart's `DateTime.parse` treats naive ISO strings as **device-local**
/// time, which would silently shift every backend timestamp by the
/// device's UTC offset. This helper re-attaches the `+08:00` offset
/// so the parsed `DateTime` represents the correct absolute moment.
///
/// Strings that already carry TZ info — either the `Z` shorthand or
/// a numeric `±HH:mm` offset — are passed through untouched. The
/// backend may evolve to send proper UTC later; this helper keeps
/// working in both modes.
///
/// **Always call `.toLocal()` on the result before formatting for
/// display** — see `AppTimeFormatter` for the display side.
DateTime parseBackendTime(String raw) {
  final hasTz = raw.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  if (hasTz) return DateTime.parse(raw);
  return DateTime.parse('$raw+08:00');
}