import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/models/chat_models.dart';

void main() {
  group('Message.fromJson', () {
    test('recognizes REST §4.3 image payload (uses `type` field)', () {
      final m = Message.fromJson(
        {
          'id': 124,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': 'https://r2.example.com/users/photos/2/abc.jpg',
          'type': 'image',
          'sentAt': '2026-06-29T18:30:00.000Z',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.image);
      expect(m.content, 'https://r2.example.com/users/photos/2/abc.jpg');
    });

    test('recognizes WS §5.2 image push (uses `messageType` field)', () {
      final m = Message.fromJson(
        {
          'id': 124,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': 'https://r2.example.com/users/photos/2/abc.jpg',
          'messageType': 'IMAGE',
          'sentAt': '2026-06-29T18:30:00.000Z',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.image);
    });

    test('falls back to text only when neither field is present', () {
      final m = Message.fromJson(
        {
          'id': 124,
          'clientId': 'cli-1',
          'conversationId': 1,
          'senderId': 2,
          'senderName': '张美玲',
          'senderAvatarLabel': '张',
          'content': '晚饭好了！',
          'sentAt': '2026-06-29T18:30:00.000Z',
        },
        currentUserId: 1,
      );
      expect(m.type, MessageType.text);
    });
  });
}
