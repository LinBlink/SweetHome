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
