import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/data/mock_data.dart';
import 'package:sweethome_flutter/models/chat_models.dart';
import 'package:sweethome_flutter/models/redpacket.dart';

void main() {
  group('Redpacket.fromJson', () {
    test('parses the §9.1 example payload (ongoing)', () {
      final rp = Redpacket.fromJson({
        'id': 1001,
        'userId': 1,
        'totalAmount': 10000,
        'totalCount': 5,
        'status': 'ongoing',
        'expiredAt': '2026-07-25T14:30:00',
        'createdAt': '2026-07-24T14:30:00',
      });
      expect(rp.id, 1001);
      expect(rp.userId, 1);
      expect(rp.totalAmount, 10000);
      expect(rp.totalCount, 5);
      expect(rp.status, RedpacketStatus.ongoing);
      // Backend timestamps are UTC+8 wall-clock; parseBackendTime
      // re-attaches the offset so .toLocal() in display code does
      // the right thing.
      expect(rp.expiredAt.year, 2026);
      expect(rp.expiredAt.month, 7);
      expect(rp.expiredAt.day, 25);
    });

    test('accepts all four §9.5 status strings', () {
      for (final s in [
        'ongoing',
        'finished',
        'expired',
        'refunded',
      ]) {
        expect(
          redpacketStatusFromString(s),
          isNotNull,
          reason: 'status $s must parse',
        );
      }
      expect(
        redpacketStatusFromString(null),
        RedpacketStatus.ongoing,
        reason: 'unknown / missing status defaults to ongoing',
      );
      expect(
        redpacketStatusFromString('GARBAGE'),
        RedpacketStatus.ongoing,
        reason: 'unknown status defaults to ongoing',
      );
    });

    test('wire round-trips through redpacketStatusToWire', () {
      expect(redpacketStatusToWire(RedpacketStatus.ongoing), 'ongoing');
      expect(redpacketStatusToWire(RedpacketStatus.finished), 'finished');
      expect(redpacketStatusToWire(RedpacketStatus.expired), 'expired');
      expect(redpacketStatusToWire(RedpacketStatus.refunded), 'refunded');
    });
  });

  group('RedpacketGrab.fromJson', () {
    test('parses the §9.3 example payload', () {
      final g = RedpacketGrab.fromJson({
        'id': 50001,
        'redpacketId': 1001,
        'userId': 7,
        'grabAmount': 2333,
        'createdAt': '2026-07-24T14:31:05',
      });
      expect(g.id, 50001);
      expect(g.redpacketId, 1001);
      expect(g.userId, 7);
      expect(g.grabAmount, 2333);
    });

    test('accepts a null `id` — §9.3 always returns it as null since '
        'the DB row is written asynchronously', () {
      final g = RedpacketGrab.fromJson({
        'id': null,
        'redpacketId': 1001,
        'userId': 7,
        'grabAmount': 2333,
        'createdAt': '2026-07-24T14:31:05',
      });
      expect(g.id, isNull);
      expect(g.redpacketId, 1001);
      expect(g.userId, 7);
      expect(g.grabAmount, 2333);
    });

    test('§9.4 shape: fills username/userAvatarUrl, owner group stays null',
        () {
      final g = RedpacketGrab.fromJson({
        'id': 50001,
        'redpacketId': 1001,
        'userId': 7,
        'username': '王小明',
        'userAvatarUrl': 'https://oss.example.com/avatars/7.jpg',
        'grabAmount': 2333,
        'createdAt': '2026-07-24T14:31:05',
      });
      expect(g.username, '王小明');
      expect(g.userAvatarUrl, 'https://oss.example.com/avatars/7.jpg');
      expect(g.redpacketOwnerId, isNull);
      expect(g.redpacketOwnerUsername, isNull);
      expect(g.redpacketOwnerUserAvatarUrl, isNull);
    });

    test(
        '§9.6 shape: fills redpacketOwner* (who sent it), grabber group '
        'stays null since the grabber is always the caller', () {
      final g = RedpacketGrab.fromJson({
        'id': 50001,
        'redpacketId': 1001,
        'userId': 7,
        'redpacketOwnerId': 1,
        'redpacketOwnerUsername': '王建国',
        'redpacketOwnerUserAvatarUrl': 'https://oss.example.com/avatars/1.jpg',
        'grabAmount': 2333,
        'createdAt': '2026-07-24T14:31:05',
      });
      expect(g.username, isNull);
      expect(g.userAvatarUrl, isNull);
      expect(g.redpacketOwnerId, 1);
      expect(g.redpacketOwnerUsername, '王建国');
      expect(g.redpacketOwnerUserAvatarUrl,
          'https://oss.example.com/avatars/1.jpg');
    });
  });

  group('Message.fromJson (REDPACKET)', () {
    test('extracts redpacketId from content (REST §4.4 `type` field)',
        () {
      final m = Message.fromJson(
        {
          'id': 124,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': '1001',
          'type': 'redpacket',
          'sentAt': '2026-07-24T14:30:00',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.redpacket);
      expect(m.redpacketId, 1001);
    });

    test('extracts redpacketId from content (WS §5.2 `messageType` field)',
        () {
      final m = Message.fromJson(
        {
          'id': 124,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': '1002',
          'messageType': 'REDPACKET',
          'sentAt': '2026-07-24T14:30:00',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.redpacket);
      expect(m.redpacketId, 1002);
    });

    test('non-redpacket messages have null redpacketId', () {
      final m = Message.fromJson(
        {
          'id': 1,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': '晚饭好了！',
          'messageType': 'TEXT',
          'sentAt': '2026-07-24T14:30:00',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.text);
      expect(m.redpacketId, isNull);
    });

    test('redpacketId falls back to null if content is not parseable', () {
      final m = Message.fromJson(
        {
          'id': 1,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': 'not-a-number',
          'messageType': 'REDPACKET',
          'sentAt': '2026-07-24T14:30:00',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.redpacket);
      expect(m.redpacketId, isNull);
    });
  });

  group('MessageType wire values', () {
    test('REDPACKET maps to uppercase apiValue and lowercase restValue', () {
      expect(MessageType.redpacket.apiValue, 'REDPACKET');
      expect(MessageType.redpacket.restValue, 'redpacket');
    });

    test('case-insensitive parse accepts REDPACKET and redpacket', () {
      expect(MessageType.fromApi('REDPACKET'), MessageType.redpacket);
      expect(MessageType.fromApi('redpacket'), MessageType.redpacket);
      expect(MessageType.fromApi('RedPacket'), MessageType.redpacket);
    });
  });

  group('MessageType wire aliases', () {
    test('§4.4 accepts both `voice` and `audio` as audio messages', () {
      // The §4.4 wire whitelist lists both spellings — they refer to
      // the same conceptual chat message (a recorded audio clip).
      // Either form should round-trip into [MessageType.voice] so the
      // voice bubble renders and the conversation-tile preview shows
      // the localized "[Voice]" / "[语音]" placeholder instead of the
      // raw URL.
      expect(MessageType.fromApi('voice'), MessageType.voice);
      expect(MessageType.fromApi('audio'), MessageType.voice);
      expect(MessageType.fromApi('VOICE'), MessageType.voice);
      expect(MessageType.fromApi('AUDIO'), MessageType.voice);
    });

    test('outbound `voice` always uses the `voice` wire spelling', () {
      // We only ship `voice` on the wire (matches existing chat flow);
      // the alias is receive-only.
      expect(MessageType.voice.restValue, 'voice');
      expect(MessageType.voice.apiValue, 'VOICE');
    });
  });

  group('MockDataSource red packet registry', () {
    test('mockRedpacketById finds a freshly created packet', () {
      final rp = Redpacket(
        id: 424242,
        userId: 1,
        totalAmount: 500,
        totalCount: 1,
        status: RedpacketStatus.ongoing,
        expiredAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );
      MockDataSource.registerCreatedRedpacket(rp);
      expect(MockDataSource.mockRedpacketById(424242), isNotNull);
      expect(MockDataSource.mockRedpacketById(424242)!.totalAmount, 500);
    });

    test('mockRedpacketById still returns null for an unregistered id', () {
      expect(MockDataSource.mockRedpacketById(999999), isNull);
    });

    test('registerRedpacketGrab is picked up by mockRedpacketGrabs', () {
      final rp = Redpacket(
        id: 424343,
        userId: 2,
        totalAmount: 500,
        totalCount: 2,
        status: RedpacketStatus.ongoing,
        expiredAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );
      MockDataSource.registerCreatedRedpacket(rp);
      expect(MockDataSource.mockRedpacketGrabs(424343), isEmpty);
      MockDataSource.registerRedpacketGrab(
        424343,
        RedpacketGrab(
          id: 1,
          redpacketId: 424343,
          userId: 1,
          grabAmount: 250,
          createdAt: DateTime.now(),
        ),
      );
      final grabs = MockDataSource.mockRedpacketGrabs(424343);
      expect(grabs, hasLength(1));
      expect(grabs.first.grabAmount, 250);
    });
  });

  group('MockDataSource red packet history (§9.5/§9.6)', () {
    test(
        'mockSentRedpackets(1) includes fixture 1001 (sent by the mock '
        'user) but not 1002 (sent by 张美玲)', () {
      final sent = MockDataSource.mockSentRedpackets(1);
      expect(sent.any((r) => r.id == 1001), isTrue);
      expect(sent.any((r) => r.id == 1002), isFalse);
    });

    test(
        'mockReceivedRedpacketGrabs(1) fills redpacketOwner* (who sent '
        'it) and leaves username null (grabber is always the caller)',
        () {
      final received = MockDataSource.mockReceivedRedpacketGrabs(1);
      final fromFixture1001 =
          received.firstWhere((g) => g.redpacketId == 1001);
      expect(fromFixture1001.redpacketOwnerId, 1);
      expect(fromFixture1001.redpacketOwnerUsername, '王建国');
      expect(fromFixture1001.username, isNull);

      final fromFixture1002 =
          received.firstWhere((g) => g.redpacketId == 1002);
      expect(fromFixture1002.redpacketOwnerId, 2);
      expect(fromFixture1002.redpacketOwnerUsername, '张美玲');
    });
  });
}