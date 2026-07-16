import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweethome_flutter/data/mock_data.dart';
import 'package:sweethome_flutter/models/chat_models.dart';
import 'package:sweethome_flutter/providers/chat_provider.dart';
import 'package:sweethome_flutter/services/chat_service.dart';
import 'package:sweethome_flutter/services/websocket_service.dart';

// A WebSocket stand-in with no background timers/sockets.
class _NoopWs extends WebSocketService {
  _NoopWs() : super(tokenProvider: () => '');

  final _c = StreamController<WsInboundMessage>.broadcast();
  @override
  Stream<WsInboundMessage> get stream => _c.stream;
  @override
  void connect() {}
  @override
  void send(WsOutboundMessage msg) {}
  @override
  void disconnect() {
    if (!_c.isClosed) _c.close();
  }
}

// Run with: flutter test --dart-define=MOCK_MODE=true test/new_conversation_flow_test.dart
//
// Covers the data half of "tap a member -> start a conversation": that
// ChatProvider.startDirectConversation actually produces a direct conversation
// the NewConversationScreen can navigate into (see _startChat). The navigation
// itself is a thin wrapper that re-provides ChatProvider to the pushed route.
void main() {
  // `ChatProvider`'s constructor hydrates from SharedPreferences on
  // init — without a binding this throws, so initialize it for the
  // test scope up front and pre-seed the SharedPreferences mock with
  // an empty map (otherwise the platform-channel `getAll` call from
  // the cache misses its mock implementation).
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  ChatProvider newProvider() => ChatProvider(
        ws: _NoopWs(),
        chatService: ChatService(() => MockDataSource.mockUser.token),
        currentUser: MockDataSource.mockUser,
      );

  test('startDirectConversation creates a direct conversation with the target',
      () async {
    final chat = newProvider();
    await chat.loadConversations();

    final conv = await chat.startDirectConversation(2); // 张美玲

    expect(conv.isGroup, isFalse);
    expect(conv.otherUserId, 2);
    expect(conv.name, '张美玲');
    // The new conversation is now in the list the UI renders.
    expect(chat.conversations.any((c) => c.id == conv.id), isTrue);

    chat.dispose();
  });

  test('startDirectConversation is idempotent (reuses an existing direct chat)',
      () async {
    final chat = newProvider();
    await chat.loadConversations();

    final first = await chat.startDirectConversation(2);
    final countAfterFirst = chat.conversations.length;
    final second = await chat.startDirectConversation(2);

    expect(second.id, first.id);
    expect(chat.conversations.length, countAfterFirst); // no duplicate

    chat.dispose();
  });

  test('Conversation.fromJson tolerates a null lastMessageAt (fresh direct chat)',
      () {
    // A just-created direct conversation (docs/api.md §4.2) has no messages,
    // so lastMessage/lastMessageAt come back null. This must not throw.
    final conv = Conversation.fromJson({
      'id': 42,
      'type': 'direct',
      'name': '张美玲',
      'avatarLabel': '张',
      'avatarColor': 'FFF4A261',
      'relationCode': 'S',
      'otherUserGender': 'female',
      'otherUserId': 2,
      'lastMessage': null,
      'lastMessageAt': null,
      'unreadCount': 0,
      'memberCount': 2,
    });

    expect(conv.id, 42);
    expect(conv.isGroup, isFalse);
    expect(conv.otherUserId, 2);
    expect(conv.lastMessage, '');
  });
}
