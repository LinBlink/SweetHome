import 'package:intl/intl.dart';

/// Formats amounts that arrive as **分 (cents)** into a display
/// string with two decimals and digit grouping (e.g. `10000 分` →
/// `"100.00"`, `1234567 分` → `"12,345.67"`). Currency prefix is the
/// caller's responsibility — pass the formatted value through
/// `l10n.balanceValue(...)` so the `¥` symbol can be localized later
/// without changing the formatter.
///
/// The formatter is intentionally minimal: one entry point,
/// no per-locale branching. The app is currently yuan-centric
/// (Chinese-market product, see AGENTS.md) so the `¥` symbol lives
/// in the .arb files rather than the formatter.
class MoneyFormatter {
  static final NumberFormat _display = NumberFormat('#,##0.00');

  /// Formats [cents] (raw int, the §2.1 / §9 wire unit) for display.
  /// Negative values render with a leading minus (e.g. refunds on
  /// the red packet detail page) — never use this for free-form text
  /// concatenation without checking sign first.
  static String format(int cents) {
    return _display.format(cents / 100.0);
  }
}