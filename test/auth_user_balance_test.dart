import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/models/auth_models.dart';

void main() {
  group('AuthUser balance field', () {
    test('defaults to 0 when not in the response', () {
      final u = AuthUser.fromJson({
        'token': 't',
        'refreshToken': 'rt',
        'user': {
          'userId': 1,
          'name': '王建国',
          'phone': '+8613800138000',
          'familyId': 1,
          'familyName': '王家',
          'role': 'admin',
        },
      });
      expect(u.balance, 0,
          reason: '§1.1/§1.2 responses don\'t include balance — '
              'must default to 0 so the profile pill doesn\'t crash');
    });

    test('parses balance from §2.1 response', () {
      final u = AuthUser.fromUserFields(
        {
          'userId': 1,
          'name': '王建国',
          'phone': '+8613800138000',
          'familyId': 1,
          'familyName': '王家',
          'role': 'admin',
          'gender': 'male',
          'balance': 10000,
        },
        token: 't',
        refreshToken: 'rt',
      );
      expect(u.balance, 10000);
    });

    test('round-trips through toPrefs / fromPrefs', () {
      const u = AuthUser(
        token: 't',
        refreshToken: 'rt',
        userId: 1,
        name: '王建国',
        phone: '+8613800138000',
        familyId: 1,
        familyName: '王家',
        role: 'admin',
        gender: 'male',
        balance: 8888,
      );
      final prefs = u.toPrefs();
      final loaded = AuthUser.fromPrefs(prefs);
      expect(loaded, isNotNull);
      expect(loaded!.balance, 8888);
    });

    test('fromPrefs tolerates missing balance row (pre-§9 install)', () {
      // Simulates a prefs file written before the balance key existed —
      // the loader must not throw.
      final loaded = AuthUser.fromPrefs({
        'token': 't',
        'refreshToken': 'rt',
        'userId': '1',
        'name': '王建国',
        'phone': '+8613800138000',
        'familyId': '1',
        'familyName': '王家',
        'role': 'admin',
        'gender': 'male',
        // no 'balance' row
      });
      expect(loaded, isNotNull);
      expect(loaded!.balance, 0);
    });

    test('copyWith updates balance without touching other fields', () {
      const u = AuthUser(
        token: 't',
        refreshToken: 'rt',
        userId: 1,
        name: '王建国',
        phone: '+8613800138000',
        familyId: 1,
        familyName: '王家',
        role: 'admin',
        gender: 'male',
        balance: 10000,
      );
      final updated = u.copyWith(balance: 5000);
      expect(updated.balance, 5000);
      expect(updated.token, u.token);
      expect(updated.userId, u.userId);
      expect(updated.name, u.name);
    });
  });
}