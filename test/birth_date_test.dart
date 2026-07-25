import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/time/birth_date.dart';

void main() {
  group('formatApiDate', () {
    test('pads to YYYY-MM-DD and carries no time component', () {
      // The backend parses this into a LocalDate; anything with a time
      // attached (as toIso8601String would produce) fails to parse.
      expect(formatApiDate(DateTime(1990, 3, 1)), '1990-03-01');
      expect(formatApiDate(DateTime(2001, 12, 25)), '2001-12-25');
      expect(formatApiDate(DateTime(1990, 3, 1, 13, 45)), '1990-03-01');
    });
  });

  group('parseApiDate', () {
    test('parses the API shape', () {
      expect(parseApiDate('1990-03-01'), DateTime(1990, 3, 1));
    });

    test('returns null rather than throwing on absent or malformed input', () {
      // A bad date on one member must not take down a whole member list.
      expect(parseApiDate(null), isNull);
      expect(parseApiDate(''), isNull);
      expect(parseApiDate('not-a-date'), isNull);
    });

    test('drops any time component so date-only comparisons stay exact', () {
      expect(parseApiDate('1990-03-01T12:30:00'), DateTime(1990, 3, 1));
    });
  });

  group('ageFrom', () {
    test('counts completed years, flipping on the birthday itself', () {
      final birth = DateTime(2000, 6, 1);
      expect(ageFrom(birth, asOf: DateTime(2025, 5, 31)), 24);
      expect(ageFrom(birth, asOf: DateTime(2025, 6, 1)), 25);
      expect(ageFrom(birth, asOf: DateTime(2025, 6, 2)), 25);
    });

    test('handles a birthday earlier in the month correctly', () {
      final birth = DateTime(2000, 6, 20);
      expect(ageFrom(birth, asOf: DateTime(2025, 6, 19)), 24);
      expect(ageFrom(birth, asOf: DateTime(2025, 6, 20)), 25);
    });

    test('is 0 for a baby born earlier this year', () {
      expect(ageFrom(DateTime(2025, 1, 5), asOf: DateTime(2025, 8, 1)), 0);
    });

    test('returns null for unknown and for future dates', () {
      // A negative age is never something worth rendering.
      expect(ageFrom(null), isNull);
      expect(ageFrom(DateTime(2030, 1, 1), asOf: DateTime(2025, 1, 1)), isNull);
    });
  });

  group('isBirthdayToday', () {
    test('matches on month and day regardless of year', () {
      final birth = DateTime(1990, 3, 1);
      expect(isBirthdayToday(birth, asOf: DateTime(2025, 3, 1)), isTrue);
      expect(isBirthdayToday(birth, asOf: DateTime(2025, 3, 2)), isFalse);
      expect(isBirthdayToday(birth, asOf: DateTime(2025, 1, 3)), isFalse);
    });

    test('unknown birth date is never a birthday', () {
      expect(isBirthdayToday(null), isFalse);
    });

    test('Feb 29 birthdays fall on Mar 1 in non-leap years', () {
      final leapling = DateTime(2000, 2, 29);
      // Leap year: the real date exists, so it matches on the day itself.
      expect(isBirthdayToday(leapling, asOf: DateTime(2024, 2, 29)), isTrue);
      expect(isBirthdayToday(leapling, asOf: DateTime(2024, 3, 1)), isFalse);
      // Non-leap year: observed on Mar 1 rather than never being observed.
      expect(isBirthdayToday(leapling, asOf: DateTime(2025, 3, 1)), isTrue);
      expect(isBirthdayToday(leapling, asOf: DateTime(2025, 2, 28)), isFalse);
      // 1900 is divisible by 100 but not 400 → not a leap year.
      expect(isBirthdayToday(leapling, asOf: DateTime(1900, 3, 1)), isTrue);
      // 2000 is divisible by 400 → a leap year, so Mar 1 is not the observance.
      expect(isBirthdayToday(leapling, asOf: DateTime(2000, 3, 1)), isFalse);
    });
  });
}
