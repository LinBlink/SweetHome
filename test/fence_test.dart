import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/models/fence.dart';
import 'package:sweethome_flutter/models/location.dart';

void main() {
  group('LocationHistory.fromJson', () {
    test('parses a full payload with multiple points', () {
      final h = LocationHistory.fromJson({
        'familyId': 1,
        'familyName': '王家',
        'userId': 4,
        'username': '王小明',
        'userAvatarUrl': null,
        'locations': [
          {
            'lng': 116.43,
            'lat': 39.90,
            'battery': 90,
            'updatedAt': '2026-07-14T08:00:00.000Z',
          },
          {
            'lng': 116.44,
            'lat': 39.91,
            'battery': 88,
            'updatedAt': '2026-07-14T08:01:00.000Z',
          },
        ],
      });
      expect(h.familyId, 1);
      expect(h.userId, 4);
      expect(h.locations, hasLength(2));
      expect(h.locations.first.lng, closeTo(116.43, 1e-9));
      expect(h.locations.last.battery, 88);
      expect(h.isEmpty, isFalse);
    });

    test('treats missing locations as empty', () {
      final h = LocationHistory.fromJson({
        'familyId': 1,
        'familyName': '王家',
        'userId': 4,
        'username': '王小明',
        'userAvatarUrl': null,
      });
      expect(h.locations, isEmpty);
      expect(h.isEmpty, isTrue);
    });

    test('LocationHistoryPoint defaults battery to -1 when missing', () {
      final p = LocationHistoryPoint.fromJson({
        'lng': 1,
        'lat': 2,
        'updatedAt': '2026-07-14T08:00:00.000Z',
      });
      expect(p.battery, -1);
    });
  });

  group('Fence.fromJson', () {
    test('parses a full payload', () {
      final f = Fence.fromJson({
        'id': 1,
        'name': '学校',
        'setterUserId': 1,
        'targetUserId': 4,
        'fenceLng': 116.4310,
        'fenceLat': 39.9012,
        'fenceRange': 200.5,
        'createdAt': '2026-07-14T10:00:00.000Z',
        'updatedAt': '2026-07-14T10:00:00.000Z',
      });
      expect(f.id, 1);
      expect(f.name, '学校');
      expect(f.setterUserId, 1);
      expect(f.targetUserId, 4);
      expect(f.fenceRange, closeTo(200.5, 1e-9));
    });

    test('tolerates a missing name (null)', () {
      final f = Fence.fromJson({
        'id': 2,
        'setterUserId': 1,
        'targetUserId': 4,
        'fenceLng': 1,
        'fenceLat': 2,
        'fenceRange': 100,
        'createdAt': '2026-07-14T10:00:00.000Z',
        'updatedAt': '2026-07-14T10:00:00.000Z',
      });
      expect(f.name, isNull);
    });
  });

  group('FenceAlarm.fromJson', () {
    test('parses a STEPPED_OUTSIDE alarm with a snapshot target', () {
      final a = FenceAlarm.fromJson({
        'id': 10,
        'fenceId': 1,
        'fenceName': '学校',
        'alarmType': 'STEPPED_OUTSIDE',
        'alarmedAt': '2026-07-14T15:30:00.000Z',
        'targetUserId': 4,
        'targetUsername': '王小明',
        'targetUserAvatarUrl': null,
      });
      expect(a.fenceName, '学校');
      expect(a.isInside, isFalse);
      expect(a.targetUsername, '王小明');
    });

    test('parses a STEPPED_INSIDE alarm', () {
      final a = FenceAlarm.fromJson({
        'id': 11,
        'fenceId': 1,
        'fenceName': '学校',
        'alarmType': 'STEPPED_INSIDE',
        'alarmedAt': '2026-07-14T15:00:00.000Z',
        'targetUserId': 4,
        'targetUsername': '王小明',
        'targetUserAvatarUrl': null,
      });
      expect(a.isInside, isTrue);
    });

    test('fenceName may be null (alarm from a since-deleted fence)', () {
      final a = FenceAlarm.fromJson({
        'id': 12,
        'fenceId': 99,
        'alarmType': 'STEPPED_OUTSIDE',
        'alarmedAt': '2026-07-14T15:00:00.000Z',
        'targetUserId': 4,
        'targetUsername': '王小明',
        'targetUserAvatarUrl': null,
      });
      expect(a.fenceName, isNull);
      expect(a.isInside, isFalse);
    });
  });
}