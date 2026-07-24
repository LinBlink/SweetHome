import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/models/moment.dart';

void main() {
  group('Moment.fromJson', () {
    test('parses full feed row (image media)', () {
      final json = {
        'id': 42,
        'userId': 7,
        'username': '王建国',
        'userAvatarUrl': 'https://r2.example/avatars/7.webp',
        'createdAt': '2026-07-15T10:00:00.000',
        'content': '早安',
        'mediaFiles': [
          {
            'type': 'image',
            'content': 'https://r2.example/photos/7/img-1.webp',
            'createdAt': '2026-07-15T10:00:00.000',
          },
        ],
      };
      final moment = Moment.fromJson(json);
      expect(moment.id, 42);
      expect(moment.userId, 7);
      expect(moment.username, '王建国');
      expect(moment.userAvatarUrl, 'https://r2.example/avatars/7.webp');
      expect(moment.content, '早安');
      expect(moment.media.length, 1);
      expect(moment.media.first.type, MomentMediaType.image);
      expect(moment.media.first.url, 'https://r2.example/photos/7/img-1.webp');
    });

    test('parses video + audio media in a single row', () {
      final json = {
        'id': 99,
        'userId': 1,
        'username': '小明',
        'createdAt': '2026-07-15T12:34:56.000',
        'content': null,
        'mediaFiles': [
          {'type': 'video', 'content': 'https://r2.example/v/1.mp4'},
          {'type': 'audio', 'content': 'https://r2.example/a/1.opus'},
        ],
      };
      final m = Moment.fromJson(json);
      expect(m.content, isNull);
      expect(m.media.length, 2);
      expect(m.media[0].type, MomentMediaType.video);
      expect(m.media[1].type, MomentMediaType.audio);
    });

    test('falls back to `media` key if `mediaFiles` absent', () {
      final json = {
        'id': 1,
        'userId': 1,
        'username': '?',
        'createdAt': '2026-07-15T12:34:56.000',
        'media': [
          {'type': 'image', 'content': 'https://r2.example/x.jpg'},
        ],
      };
      final m = Moment.fromJson(json);
      expect(m.media.length, 1);
      expect(m.media.first.type, MomentMediaType.image);
    });

    test('empty content string renders as null', () {
      final json = {
        'id': 2,
        'userId': 3,
        'username': '张三',
        'createdAt': '2026-07-15T10:00:00.000',
        'content': '',
        'mediaFiles': [
          {'type': 'image', 'content': 'https://r2.example/y.jpg'},
        ],
      };
      final m = Moment.fromJson(json);
      expect(m.content, isNull);
    });

    test('unknown media type falls back to image (avoids throwing on parse)', () {
      // The §7.1 server whitelist is enforced at publish; an
      // unknown value here would mean a server-side schema drift.
      final json = {
        'id': 3,
        'userId': 4,
        'username': '李四',
        'createdAt': '2026-07-15T10:00:00.000',
        'content': 'hi',
        'mediaFiles': [
          {'type': 'video360', 'content': 'https://r2.example/q.webm'},
        ],
      };
      final m = Moment.fromJson(json);
      expect(m.media.first.type, MomentMediaType.image);
    });

    test('createdAt parses a TZ-naive UTC+8 wall clock', () {
      // Backend contract (§6/§7): "2026-07-15T10:00:00.000" with no
      // TZ suffix; parseBackendTime re-attaches +08:00 so the value
      // represents a concrete instant.
      final json = {
        'id': 4,
        'userId': 5,
        'username': '?',
        'createdAt': '2026-07-15T10:00:00.000',
        'content': '',
        'mediaFiles': <Map<String, dynamic>>[],
      };
      final m = Moment.fromJson(json);
      // 10:00 +08:00 == 02:00 UTC
      expect(m.createdAt.toUtc().hour, 2);
      expect(m.createdAt.toUtc().minute, 0);
    });

    test('family-only feed row leaves familyId / familyName null', () {
      // §7.2 (`GET /moment/myfamily`) doesn't include the family
      // identifier — same DTO is used for both feeds but the
      // family-only list returns these as missing. The UI gates the
      // "来自 {familyName}" badge on the field being non-null + the
      // viewer not being the author (see MomentCard._AuthorRow), so
      // a null here means "this is intra-family, no badge".
      final json = {
        'id': 1,
        'userId': 1,
        'username': 'me',
        'createdAt': '2026-07-15T10:00:00.000',
        'content': 'hi',
        'mediaFiles': <Map<String, dynamic>>[],
      };
      final m = Moment.fromJson(json);
      expect(m.familyId, isNull);
      expect(m.familyName, isNull);
    });

    test('public-feed row carries familyId + familyName (§7.3)', () {
      // §7.3 (`GET /moment/public`) adds these two fields for
      // cross-family disambiguation — "李秀英" by herself doesn't
      // tell you which family, the familyName suffix does.
      final json = {
        'id': 8,
        'userId': 5,
        'username': '李秀英',
        'userAvatarUrl': 'https://r2.example/avatars/5.webp',
        'familyId': 3,
        'familyName': '李家',
        'createdAt': '2026-07-18T09:00:00.000',
        'content': '我们家今天包了饺子',
        'mediaFiles': [
          {
            'type': 'image',
            'content': 'https://r2.example/photos/5/dumpling.jpg',
            'createdAt': '2026-07-18T09:00:00.000',
          },
        ],
      };
      final m = Moment.fromJson(json);
      expect(m.familyId, 3);
      expect(m.familyName, '李家');
      expect(m.media.length, 1);
    });

    test('Moment.toJson round-trips familyId + familyName', () {
      final m = Moment(
        id: 1,
        userId: 1,
        username: 'me',
        userAvatarUrl: null,
        createdAt: DateTime.utc(2026, 7, 15, 2, 0, 0),
        content: 'hi',
        media: const [],
        familyId: 42,
        familyName: '王家',
      );
      final out = m.toJson();
      expect(out['familyId'], 42);
      expect(out['familyName'], '王家');
      // Round-tripping back via fromJson reconstructs the same value.
      final round = Moment.fromJson(out);
      expect(round.familyId, 42);
      expect(round.familyName, '王家');
    });

    test('Moment.toJson omits familyId / familyName when null', () {
      // Both fields are JSON-optional — a row with neither set should
      // not write them on the wire (the server only includes them
      // on §7.3 rows). Required so a cached family-feed moment
      // serialized and sent back survives without sprouting ghost
      // fields.
      final m = Moment(
        id: 1,
        userId: 1,
        username: 'me',
        userAvatarUrl: null,
        createdAt: DateTime.utc(2026, 7, 15, 2, 0, 0),
        content: 'hi',
        media: const [],
      );
      final out = m.toJson();
      expect(out.containsKey('familyId'), false);
      expect(out.containsKey('familyName'), false);
    });
  });

  group('LikerEntry / MomentLikeDetail', () {
    test('LikerEntry.fromJson trims optional avatar', () {
      final entry = LikerEntry.fromJson({
        'userId': 12,
        'username': '王嫂',
        'likeCount': 4,
      });
      expect(entry.userId, 12);
      expect(entry.username, '王嫂');
      expect(entry.userAvatarUrl, isNull);
      expect(entry.likeCount, 4);
    });

    test('LikerEntry defaults likeCount to 1 when missing', () {
      final entry = LikerEntry.fromJson({
        'userId': 1,
        'username': 'x',
      });
      expect(entry.likeCount, 1);
    });

    test('MomentLikeDetail.fromJson aggregates the list', () {
      final detail = MomentLikeDetail.fromJson({
        'totalLikes': 6,
        'likers': [
          {'userId': 1, 'username': 'A', 'likeCount': 3},
          {'userId': 2, 'username': 'B', 'likeCount': 3},
        ],
      });
      expect(detail.totalLikes, 6);
      expect(detail.likers.length, 2);
      expect(detail.likers[0].likeCount, 3);
    });

    test('MomentLikeDetail.fromJson handles empty list', () {
      final detail = MomentLikeDetail.fromJson({
        'totalLikes': 0,
        'likers': <Map<String, dynamic>>[],
      });
      expect(detail.likers, isEmpty);
      expect(detail.totalLikes, 0);
    });
  });
}
