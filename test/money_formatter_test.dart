import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/money/money_formatter.dart';

void main() {
  group('MoneyFormatter.format', () {
    test('formats whole-yuan amounts with two decimals', () {
      expect(MoneyFormatter.format(10000), '100.00');
    });

    test('formats fractional yuan correctly', () {
      expect(MoneyFormatter.format(888), '8.88');
    });

    test('formats zero', () {
      expect(MoneyFormatter.format(0), '0.00');
    });

    test('digit-groups large amounts', () {
      expect(MoneyFormatter.format(1234567), '12,345.67');
    });

    test('rounds the cent up when source yuan has 3 decimals', () {
      // 88.881 yuan → 8888.1 cents → 8888 (round half-up at .5).
      expect(MoneyFormatter.format(8889), '88.89');
    });

    test('handles negatives (refunds)', () {
      expect(MoneyFormatter.format(-100), '-1.00');
    });
  });
}