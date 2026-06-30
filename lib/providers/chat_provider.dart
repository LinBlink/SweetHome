import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/app_config.dart';
import '../core/app_colors.dart';
import '../data/mock_data.dart';
import '../models/chat_models.dart';
import '../models/auth_models.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _ws;
  final ChatService _chatService;
  final AuthUser _currentUser;

  List<Conversation> _conversations = [];
  final Map<int, List<Message>> _messages = {};
  final Map<int, bool> _loadingMessages = {};
  final Map<int, int?> _cursors = {};
  bool _isLoadingConversations = false;
  String? _connectionError;
  StreamSubscription<WsInboundMessage>? _wsSub;
  final _uuid = const Uuid();

  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get connectionError => _connectionError;
  List<Message> messagesFor(int convId) => _messages[convId] ?? [];
  bool isLoadingMessages(int convId) => _loadingMessages[convId] ?? false;
  bool hasMore(int convId) => _cursors[convId] != null;

  ChatProvider({
    required WebSocketService ws,
    required ChatService chatService,
    required AuthUser currentUser,
  })  : _ws = ws,
        _chatService = chatService,
        _currentUser = currentUser {
    _ws.connect(_currentUser.token);
    _wsSub = _ws.stream.listen(_handleWsMessage);
  }

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    notifyListeners();
    try {
      if (AppConfig.mockMode) {
        await Future.delayed(const Duration(milliseconds: 400));
        _conversations = List.from(MockDataSource.conversations);
      } else {
        _conversations = await _chatService.fetchConversations();
      }
    } catch (_) {
      if (_conversations.isEmpty) _conversations = [];
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int conversationId, {bool loadMore = false}) async {
    if (_loadingMessages[conversationId] == true) return;
    if (loadMore && _cursors[conversationId] == null && _messages[conversationId] != null) return;

    _loadingMessages[conversationId] = true;
    notifyListeners();
    try {
      if (AppConfig.mockMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!loadMore) {
          _messages[conversationId] = MockDataSource.messagesFor(conversationId);
          _cursors[conversationId] = null;
        }
      } else {
        final result = await _chatService.fetchMessages(
          conversationId,
          before: loadMore ? _cursors[conversationId] : null,
          currentUserId: _currentUser.userId,
        );
        if (loadMore) {
          _messages[conversationId] = [
            ...result.messages,
            ...(_messages[conversationId] ?? []),
          ];
        } else {
          _messages[conversationId] = result.messages;
        }
        _cursors[conversationId] = result.hasMore ? result.nextCursor : null;
      }
    } catch (_) {
      if (_messages[conversationId] == null) _messages[conversationId] = [];
    } finally {
      _loadingMessages[conversationId] = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int conversationId, String content) async {
    final clientId = _uuid.v4();
    final optimistic = Message(
      clientId: clientId,
      conversationId: conversationId,
      senderId: _currentUser.userId,
      senderName: _currentUser.name,
      senderAvatarLabel: _currentUser.name.isNotEmpty ? _currentUser.name[0] : '我',
      senderAvatarColor: AppColors.primary,
      content: content,
      type: MessageType.text,
      sentAt: DateTime.now(),
      isMe: true,
      isPending: true,
    );

    _messages[conversationId] ??= [];
    _messages[conversationId]!.add(optimistic);
    _updateConversationLastMessage(conversationId, content);
    notifyListeners();

    try {
      if (AppConfig.mockMode) {
        await Future.delayed(const Duration(milliseconds: 200));
        final confirmed = optimistic.copyWith(isPending: false);
        _replaceOptimistic(conversationId, clientId, confirmed);
      } else {
        final wsMsg = WsOutboundMessage(
          type: 'SEND_MESSAGE',
          payload: {
            'conversationId': conversationId,
            'content': content,
            'messageType': 'text',
            'clientId': clientId,
          },
        );
        _ws.send(wsMsg);
      }
    } catch (_) {
      if (!AppConfig.mockMode) {
        try {
          final sent = await _chatService.sendMessage(
            conversationId, content, clientId,
            currentUserId: _currentUser.userId,
          );
          _replaceOptimistic(conversationId, clientId, sent);
          notifyListeners();
        } catch (_) {
          _replaceOptimistic(conversationId, clientId, optimistic.copyWith(isPending: false));
          notifyListeners();
        }
      }
    }
  }

  void setActiveConversation(int convId) {
    _ws.send(WsOutboundMessage(
      type: 'JOIN_CONVERSATION',
      payload: {'conversationId': convId},
    ));
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx >= 0) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  void _handleWsMessage(WsInboundMessage msg) {
    switch (msg.type) {
      case 'NEW_MESSAGE':
        final m = Message.fromJson(msg.data, currentUserId: _currentUser.userId);
        _messages[m.conversationId] ??= [];
        final existingIdx = _messages[m.conversationId]!
            .indexWhere((x) => x.clientId == m.clientId);
        if (existingIdx >= 0) {
          _messages[m.conversationId]![existingIdx] = m;
        } else {
          _messages[m.conversationId]!.add(m);
        }
        _updateConversationLastMessage(m.conversationId, m.content);
        notifyListeners();

      case 'ERROR':
        _connectionError = msg.data['message'] as String?;
        notifyListeners();
    }
  }

  void _replaceOptimistic(int convId, String clientId, Message replacement) {
    final list = _messages[convId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.clientId == clientId);
    if (idx >= 0) list[idx] = replacement;
  }

  void _updateConversationLastMessage(int convId, String content) {
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx >= 0) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessage: content,
        lastMessageAt: DateTime.now(),
      );
    }
  }

  void dismissConnectionError() {
    _connectionError = null;
    notifyListeners();
  }

  void reconnect() {
    _connectionError = null;
    _ws.connect(_currentUser.token);
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws.disconnect();
    super.dispose();
  }
}
