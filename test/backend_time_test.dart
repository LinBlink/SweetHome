import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/time/backend_time.dart';

// Backend contract: timestamps come back as naive ISO-8601 strings
// representing UTC+8 wall-clock time. `parseBackendTime` must
// re-attach the +08:00 offset so Dart treats the wall-clock as a
// concrete instant, not as device-local.

void main() {
  group('parseBackendTime', () {
    test('naive ISO is interpreted as UTC+8 wall-clock', () {
      // 16:00:00 in Beijing = 08:00:00 UTC.
      final parsed = parseBackendTime('2026-07-14T16:00:00');
      expect(parsed.isUtc, isTrue);
      expect(parsed.hour, 8);
      expect(parsed.minute, 0);
      expect(parsed.day, 14);
    });

    test('Z suffix is passed through unchanged', () {
      final parsed = parseBackendTime('2026-07-14T08:00:00.000Z');
      expect(parsed.isUtc, isTrue);
      expect(parsed.hour, 8);
      expect(parsed.minute, 0);
    });

    test('numeric offset (+08:00) is passed through unchanged', () {
      final parsed = parseBackendTime('2026-07-14T16:00:00+08:00');
      expect(parsed.isUtc, isTrue);
      expect(parsed.hour, 8);
    });

    test('numeric offset (-05:00) is passed through unchanged', () {
      final parsed = parseBackendTime('2026-07-14T03:00:00-05:00');
      expect(parsed.isUtc, isTrue);
      expect(parsed.hour, 8);
    });

    test('naive vs Z are equivalent when wall-clock is UTC+8', () {
      final naive = parseBackendTime('2026-07-14T16:00:00');
      final z = parseBackendTime('2026-07-14T08:00:00.000Z');
      expect(naive.isAtSameMomentAs(z), isTrue);
    });

    test('non-Z millisecond fractions are preserved', () {
      final parsed = parseBackendTime('2026-07-14T16:00:00.123');
      expect(parsed.millisecond, 123);
      expect(parsed.hour, 8);
    });
  });
}