import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/models/join_request.dart';

void main() {
  group('JoinRequest.fromJson', () {
    test('parses a full API payload', () {
      final req = JoinRequest.fromJson({
        'requestId': 42,
        'requesterName': '王小明',
        'requesterPhone': '+8613800138099',
        'requesterGender': 'male',
        'relationType': 'CHILD_OF',
        'targetMemberName': '王建国',
        'message': 'hi',
        'createdAt': '2026-07-13T10:00:00.000Z',
        'status': 'pending',
      });
      expect(req.requestId, 42);
      expect(req.requesterName, '王小明');
      expect(req.requesterPhone, '+8613800138099');
      expect(req.requesterGender, 'male');
      expect(req.relationType, 'CHILD_OF');
      expect(req.targetMemberName, '王建国');
      expect(req.message, 'hi');
      expect(req.createdAt.toUtc(), DateTime.utc(2026, 7, 13, 10));
      expect(req.status, 'pending');
    });

    test('omitted status / message default safely', () {
      final req = JoinRequest.fromJson({
        'requestId': 1,
        'requesterName': 'x',
        'requesterPhone': 'x',
        'requesterGender': 'female',
        'relationType': 'SPOUSE_OF',
        'targetMemberName': 'y',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });
      expect(req.status, 'pending');
      expect(req.message, isNull);
    });

    test('relationNoun maps each backend relationType to its enum', () {
      final cases = <String, RelationNoun>{
        'CHILD_OF': RelationNoun.child,
        'PARENT_OF': RelationNoun.parent,
        'SPOUSE_OF': RelationNoun.spouse,
        'SIBLING_OF': RelationNoun.sibling,
        'UNKNOWN_TYPE': RelationNoun.unknown,
      };
      cases.forEach((relType, expectedNoun) {
        final r = JoinRequest.fromJson({
          'requestId': 1,
          'requesterName': 'a',
          'requesterPhone': 'b',
          'requesterGender': 'male',
          'relationType': relType,
          'targetMemberName': 'c',
          'createdAt': '2026-01-01T00:00:00.000Z',
        });
        expect(r.relationNoun, expectedNoun,
            reason: 'relationType=$relType should map to $expectedNoun');
      });
    });
  });
}