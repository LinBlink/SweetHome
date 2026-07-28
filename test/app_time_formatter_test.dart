import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sweethome_flutter/core/time/app_time_formatter.dart';

// `AppTimeFormatter` is the only place the app formats backend
// timestamps for display. These tests pin down the per-locale shape
// so a backend-side contract change can't silently regress the UI.

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  // `forMessageBubble` / `forConversationTile` branch on "today /
  // yesterday / this week / older", so every one of those assertions
  // depends on what "now" is. Pin it to a fixed instant and inject it
  // via the `clock` hook rather than reading the wall clock: with the
  // real clock, `today` (14:30) is in the *future* whenever the suite
  // runs before 14:30, so it lands in the "just now" branch and the
  // "today → HH:mm" case fails every morning. 18:00 is late enough
  // that the 14:30 fixtures are comfortably in the past.
  final now = DateTime(2026, 7, 28, 18, 00);
  DateTime fixedClock() => now;
  final today = DateTime(now.year, now.month, now.day, 14, 30);
  final sameHourYesterday = today.subtract(const Duration(days: 1));
  final tenDaysAgo = today.subtract(const Duration(days: 10));

  group('AppTimeFormatter.forMessageBubble', () {
    test('zh returns HH:mm for today', () {
      final s = AppTimeFormatter(const Locale('zh'), clock: fixedClock).forMessageBubble(today);
      expect(s, '14:30');
    });

    test('zh returns M月d日 HH:mm for > 7 days ago', () {
      final s = AppTimeFormatter(const Locale('zh'), clock: fixedClock).forMessageBubble(tenDaysAgo);
      // `MMMd` pattern expands to `M月d日` for zh locales (intl
      // does the CJK suffix localization natively).
      expect(s, '${tenDaysAgo.month}月${tenDaysAgo.day}日 14:30');
    });

    test('en returns MM/dd HH:mm for > 7 days ago', () {
      final s = AppTimeFormatter(const Locale('en'), clock: fixedClock).forMessageBubble(tenDaysAgo);
      final mm = tenDaysAgo.month.toString().padLeft(2, '0');
      final dd = tenDaysAgo.day.toString().padLeft(2, '0');
      expect(s, '$mm/$dd 14:30');
    });

    test('ja returns MM/dd HH:mm for > 7 days ago', () {
      final s = AppTimeFormatter(const Locale('ja'), clock: fixedClock).forMessageBubble(tenDaysAgo);
      final mm = tenDaysAgo.month.toString().padLeft(2, '0');
      final dd = tenDaysAgo.day.toString().padLeft(2, '0');
      expect(s, '$mm/$dd 14:30');
    });
  });

  group('AppTimeFormatter.forConversationTile', () {
    const zh = Locale('zh');
    final fmt = AppTimeFormatter(zh, clock: fixedClock);

    test('today → HH:mm', () {
      expect(
        fmt.forConversationTile(today,
            timeJustNow: '刚刚', timeMinutesAgo: (m) => '$m分钟前', timeYesterday: '昨天'),
        '14:30',
      );
    });

    test('yesterday → localized "yesterday"', () {
      expect(
        fmt.forConversationTile(sameHourYesterday,
            timeJustNow: '刚刚', timeMinutesAgo: (m) => '$m分钟前', timeYesterday: '昨天'),
        '昨天',
      );
    });

    test('> 1 day ago → M月d日 for zh', () {
      expect(
        fmt.forConversationTile(tenDaysAgo,
            timeJustNow: '刚刚', timeMinutesAgo: (m) => '$m分钟前', timeYesterday: '昨天'),
        '${tenDaysAgo.month}月${tenDaysAgo.day}日',
      );
    });

    // "Yesterday" is a calendar question, not an elapsed-hours one. These two
    // pin the boundary from both sides — the old `diff.inDays == 1` check got
    // both of them wrong.
    test('yesterday evening is still "yesterday" this morning (13h apart)', () {
      final morningFmt = AppTimeFormatter(zh, clock: () => DateTime(2026, 7, 28, 9, 00));
      expect(
        morningFmt.forConversationTile(DateTime(2026, 7, 27, 20, 00),
            timeJustNow: '刚刚', timeMinutesAgo: (m) => '$m分钟前', timeYesterday: '昨天'),
        '昨天',
      );
    });

    test('two days ago is NOT "yesterday", even at only 25h apart', () {
      final afterMidnightFmt =
          AppTimeFormatter(zh, clock: () => DateTime(2026, 7, 28, 0, 30));
      expect(
        afterMidnightFmt.forConversationTile(DateTime(2026, 7, 26, 23, 00),
            timeJustNow: '刚刚', timeMinutesAgo: (m) => '$m分钟前', timeYesterday: '昨天'),
        '7月26日',
      );
    });

    test('en > 1 day ago → MM/dd', () {
      final enFmt = AppTimeFormatter(const Locale('en'), clock: fixedClock);
      final mm = tenDaysAgo.month.toString().padLeft(2, '0');
      final dd = tenDaysAgo.day.toString().padLeft(2, '0');
      expect(
        enFmt.forConversationTile(tenDaysAgo,
            timeJustNow: 'just now',
            timeMinutesAgo: (m) => '${m}m',
            timeYesterday: 'yesterday'),
        '$mm/$dd',
      );
    });
  });

  group('AppTimeFormatter.forRecordList', () {
    test('zh uses M月d日 HH:mm', () {
      final s = AppTimeFormatter(const Locale('zh'), clock: fixedClock).forRecordList(today);
      expect(s, '${today.month}月${today.day}日 14:30');
    });

    test('en uses yyyy-MM-dd HH:mm', () {
      final s = AppTimeFormatter(const Locale('en'), clock: fixedClock).forRecordList(today);
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      expect(s, '${today.year}-$mm-$dd 14:30');
    });

    test('ko uses yyyy-MM-dd HH:mm', () {
      final s = AppTimeFormatter(const Locale('ko'), clock: fixedClock).forRecordList(today);
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      expect(s, '${today.year}-$mm-$dd 14:30');
    });
  });

  group('AppTimeFormatter.forDateOnly / forTimeOnly', () {
    test('zh date only', () {
      expect(
        AppTimeFormatter(const Locale('zh'), clock: fixedClock).forDateOnly(today),
        '${today.month}月${today.day}日',
      );
    });
    test('en date only', () {
      final mm = today.month.toString().padLeft(2, '0');
      final dd = today.day.toString().padLeft(2, '0');
      expect(
        AppTimeFormatter(const Locale('en'), clock: fixedClock).forDateOnly(today),
        '${today.year}-$mm-$dd',
      );
    });
    test('time only is locale-neutral HH:mm', () {
      expect(AppTimeFormatter(const Locale('zh'), clock: fixedClock).forTimeOnly(today), '14:30');
      expect(AppTimeFormatter(const Locale('en'), clock: fixedClock).forTimeOnly(today), '14:30');
    });
  });

  group('zh_Hans / zh_Hant use CJK shapes too', () {
    test('zh_Hans forMessageBubble', () {
      expect(
        AppTimeFormatter(const Locale('zh', 'Hans'), clock: fixedClock)
            .forMessageBubble(tenDaysAgo),
        '${tenDaysAgo.month}月${tenDaysAgo.day}日 14:30',
      );
    });
    test('zh_Hant forMessageBubble', () {
      expect(
        AppTimeFormatter(const Locale('zh', 'Hant'), clock: fixedClock)
            .forMessageBubble(tenDaysAgo),
        '${tenDaysAgo.month}月${tenDaysAgo.day}日 14:30',
      );
    });
  });
}