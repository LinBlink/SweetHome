import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/models/location.dart';

void main() {
  group('MemberLocation.fromJson', () {
    test('parses a full payload and uses -1 for missing battery', () {
      final m = MemberLocation.fromJson({
        'userId': 1,
        'username': '王建国',
        'userAvatarUrl': null,
        'lng': 116.3975,
        'lat': 39.9087,
        'updatedAt': '2026-07-13T10:00:00.000Z',
      });
      expect(m.battery, -1);
      expect(m.userAvatarUrl, isNull);
      expect(m.lng, closeTo(116.3975, 1e-9));
      expect(m.lat, closeTo(39.9087, 1e-9));
    });

    test('preserves battery when present', () {
      final m = MemberLocation.fromJson({
        'userId': 2,
        'username': 'x',
        'lng': 1,
        'lat': 2,
        'battery': 64,
        'updatedAt': '2026-07-13T10:00:00.000Z',
      });
      expect(m.battery, 64);
    });
  });

  group('MemberLocation.isFresh / minutesAgo', () {
    final base = DateTime.now();
    MemberLocation make(Duration ago) => MemberLocation.fromJson({
      'userId': 1,
      'username': 'x',
      'lng': 0,
      'lat': 0,
      'battery': 50,
      'updatedAt': base.subtract(ago).toUtc().toIso8601String(),
    });

    test('a fix from now is fresh with 0 minutes', () {
      final m = make(Duration.zero);
      expect(m.isFresh, isTrue);
      expect(m.minutesAgo, 0);
    });

    test('a fix from 5 min ago is fresh (under 10-min window)', () {
      expect(make(const Duration(minutes: 5)).isFresh, isTrue);
    });

    test('a fix from 11 min ago is NOT fresh (past the window)', () {
      expect(make(const Duration(minutes: 11)).isFresh, isFalse);
    });

    test('minutesAgo never goes negative for future timestamps', () {
      // Shouldn't happen in practice (server time vs client clock
      // skew), but the model guards against negative values.
      final future = MemberLocation.fromJson({
        'userId': 1,
        'username': 'x',
        'lng': 0,
        'lat': 0,
        'battery': 50,
        'updatedAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String(),
      });
      expect(future.minutesAgo, 0);
    });
  });

  group('LocationReport.toJson', () {
    test('omits the battery field when null', () {
      final r = LocationReport(
        lng: 116.3975,
        lat: 39.9087,
        updateTime: DateTime.utc(2026, 7, 13, 10, 0, 0),
      );
      final json = r.toJson();
      expect(json.containsKey('battery'), isFalse);
      expect(json['lng'], 116.3975);
      expect(json['lat'], 39.9087);
      // updateTime is serialized as UTC+8 wall-clock ISO-8601 with
      // no TZ suffix, matching the backend's contract — see
      // `parseBackendTime` for the symmetric reader. `DateTime.utc(2026,
      // 7, 13, 10, 0, 0)` is 10:00 UTC = 18:00 in Beijing.
      expect(json['updateTime'], '2026-07-13T18:00:00.000');
    });

    test('includes battery when set', () {
      final r = LocationReport(
        lng: 1,
        lat: 2,
        battery: 76,
        updateTime: DateTime.utc(2026, 1, 1),
      );
      expect(r.toJson()['battery'], 76);
    });
  });

  group('FamilyLocations.fromJson', () {
    test('parses family payload with N members', () {
      final f = FamilyLocations.fromJson({
        'familyId': 1,
        'familyName': '王家',
        'onlineMemberCount': 2,
        'totalMemberCount': 3,
        'familyMemberLocations': [
          {
            'userId': 1,
            'username': 'a',
            'lng': 1,
            'lat': 1,
            'battery': 50,
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
          {
            'userId': 2,
            'username': 'b',
            'lng': 2,
            'lat': 2,
            'battery': 30,
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
        ],
      });
      expect(f.onlineMemberCount, 2);
      expect(f.totalMemberCount, 3);
      expect(f.familyMemberLocations.length, 2);
    });

    test('handles a missing familyMemberLocations key (empty list)', () {
      final f = FamilyLocations.fromJson({
        'familyId': 1,
        'familyName': 'x',
        'onlineMemberCount': 0,
        'totalMemberCount': 5,
      });
      expect(f.familyMemberLocations, isEmpty);
    });
  });
}
