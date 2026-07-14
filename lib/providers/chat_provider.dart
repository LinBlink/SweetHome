import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/app_config.dart';
import '../core/app_colors.dart';
import '../data/mock_data.dart';
import '../models/api_exception.dart';
import '../models/chat_models.dart';
import '../models/auth_models.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _ws;
  final ChatService _chatService;
  final AuthUser _currentUser;
  final Future<bool> Function()? _onUnauthorized;

  List<Conversation> _conversations = [];
  final Map<int, List<Message>> _messages = {};
  final Map<int, bool> _loadingMessages = {};
  final Map<int, int?> _cursors = {};
  bool _isLoadingConversations = false;
  String? _connectionError;
  String? _error;
  StreamSubscription<WsInboundMessage>? _wsSub;
  final _uuid = const Uuid();
  final Set<int> _onlineUserIds = {};

  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get connectionError => _connectionError;
  String? get error => _error;
  List<Message> messagesFor(int convId) => _messages[convId] ?? [];
  bool isLoadingMessages(int convId) => _loadingMessages[convId] ?? false;
  bool hasMore(int convId) => _cursors[convId] != null;

  /// Live online status from WS `USER_STATUS` pushes — see docs/api.md §5.2.
  /// Only reflects users the server has actually pushed a status for since
  /// this session connected; unknown users default to offline.
  bool isUserOnline(int userId) => _onlineUserIds.contains(userId);

  ChatProvider({
    required WebSocketService ws,
    required ChatService chatService,
    required AuthUser currentUser,
    Future<bool> Function()? onUnauthorized,
  }) : _ws = ws,
       _chatService = chatService,
       _currentUser = currentUser,
       _onUnauthorized = onUnauthorized {
    _ws.connect(_currentUser.token);
    _wsSub = _ws.stream.listen(_handleWsMessage);
  }

  /// Routes [e] to either a display-only error or, for expired/invalid
  /// auth (401), a token-refresh attempt (falls back to logout inside the
  /// [_onUnauthorized] callback if the refresh itself fails — see
  /// docs/api.md §1.3). Fire-and-forget: callers don't need to wait for the
  /// refresh before their own error handling continues.
  void _handleApiException(ApiException e) {
    if (e.code == 401) {
      _onUnauthorized?.call();
    } else {
      _error = e.message;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
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
    } on ApiException catch (e) {
      _handleApiException(e);
      if (_conversations.isEmpty) _conversations = [];
    } catch (_) {
      if (_conversations.isEmpty) _conversations = [];
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// Starts (or reuses) a direct conversation with [targetUserId] — see
  /// docs/api.md §4.2. Idempotent: if a direct conversation with that user
  /// already exists, returns it instead of creating a duplicate.
  Future<Conversation> startDirectConversation(int targetUserId) async {
    for (final c in _conversations) {
      if (!c.isGroup && c.otherUserId == targetUserId) return c;
    }

    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final member = MockDataSource.familyGraph.memberById(targetUserId);
      final newConv = Conversation(
        id:
            (_conversations.map((c) => c.id).fold(0, (a, b) => a > b ? a : b)) +
            1,
        name: member?.name ?? '',
        isGroup: false,
        avatarLabel: MockDataSource.avatarInitialFor(targetUserId),
        avatarColor: MockDataSource.avatarColorFor(targetUserId),
        relationCode: MockDataSource.relationCodeFor(targetUserId),
        otherUserGender: member?.gender,
        otherUserId: targetUserId,
        lastMessage: '',
        lastMessageAt: DateTime.now(),
        unreadCount: 0,
        memberCount: 2,
      );
      _conversations = [newConv, ..._conversations];
      notifyListeners();
      return newConv;
    }

    final conv = await _chatService.createDirectConversation(targetUserId);
    final idx = _conversations.indexWhere((c) => c.id == conv.id);
    if (idx >= 0) {
      _conversations[idx] = conv;
    } else {
      _conversations = [conv, ..._conversations];
    }
    notifyListeners();
    return conv;
  }

  Future<void> loadMessages(int conversationId, {bool loadMore = false}) async {
    if (_loadingMessages[conversationId] == true) return;
    if (loadMore &&
        _cursors[conversationId] == null &&
        _messages[conversationId] != null)
      return;

    _loadingMessages[conversationId] = true;
    notifyListeners();
    try {
      if (AppConfig.mockMode) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!loadMore) {
          _messages[conversationId] = MockDataSource.messagesFor(
            conversationId,
          );
          _cursors[conversationId] = null;
        }
      } else {
        final result = await _chatService.fetchMessages(
          conversationId,
          before: loadMore ? _cursors[conversationId] : null,
          currentUserId: _currentUser.userId,
        );
        // Backend returns pages ordered by `id DESC` (newest first within
        // the page) — docs/api.md §4.3. The chat room renders with the
        // convention `_messages[length - 1 - i]` over a reverse: true
        // ListView, which assumes ASC time order (oldest first, newest
        // last). Flip the page once at the boundary so the rest of the
        // provider can keep appending (WS / optimistic-send) uniformly.
        final pageOldestFirst = result.messages.reversed.toList();
        if (loadMore) {
          _messages[conversationId] = [
            ...pageOldestFirst,
            ...(_messages[conversationId] ?? []),
          ];
        } else {
          _messages[conversationId] = pageOldestFirst;
        }
        _cursors[conversationId] = result.hasMore ? result.nextCursor : null;
      }
    } on ApiException catch (e) {
      _handleApiException(e);
      if (_messages[conversationId] == null) _messages[conversationId] = [];
    } catch (_) {
      if (_messages[conversationId] == null) _messages[conversationId] = [];
    } finally {
      _loadingMessages[conversationId] = false;
      notifyListeners();
    }
    if (!loadMore) _syncReadState(conversationId);
  }

  /// Syncs the read cursor to the backend — WS `READ` frame for real-time
  /// propagation plus a REST `PUT /read` fallback (see docs/api.md §4.5/§5.2).
  /// Fire-and-forget: failures don't surface to the UI, this is best-effort.
  void _syncReadState(int conversationId) {
    if (AppConfig.mockMode) return;
    final msgs = _messages[conversationId];
    if (msgs == null || msgs.isEmpty) return;
    int? lastServerId;
    for (final m in msgs) {
      final id = m.serverId;
      if (id != null && (lastServerId == null || id > lastServerId))
        lastServerId = id;
    }
    if (lastServerId == null) return;
    _ws.send(
      WsOutboundMessage(
        type: 'READ',
        payload: {
          'conversationId': conversationId,
          'lastReadMessageId': lastServerId,
        },
      ),
    );
    _chatService.markRead(conversationId, lastServerId).catchError((_) {});
  }

  Future<void> sendMessage(int conversationId, String content) async {
    final clientId = _uuid.v4();
    final optimistic = Message(
      clientId: clientId,
      conversationId: conversationId,
      senderId: _currentUser.userId,
      senderName: _currentUser.name,
      senderAvatarLabel: _currentUser.name.isNotEmpty
          ? _currentUser.name[0]
          : '我',
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
            'messageType': MessageType.text.apiValue,
            'clientId': clientId,
          },
        );
        _ws.send(wsMsg);
      }
    } catch (_) {
      if (!AppConfig.mockMode) {
        try {
          final sent = await _chatService.sendMessage(
            conversationId,
            content,
            clientId,
            currentUserId: _currentUser.userId,
          );
          _replaceOptimistic(conversationId, clientId, sent);
          notifyListeners();
        } on ApiException catch (e) {
          _handleApiException(e);
          _replaceOptimistic(
            conversationId,
            clientId,
            optimistic.copyWith(isPending: false),
          );
          notifyListeners();
        } catch (_) {
          _replaceOptimistic(
            conversationId,
            clientId,
            optimistic.copyWith(isPending: false),
          );
          notifyListeners();
        }
      }
    }
  }

  void setActiveConversation(int convId) {
    _ws.send(
      WsOutboundMessage(
        type: 'JOIN_CONVERSATION',
        payload: {'conversationId': convId},
      ),
    );
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx >= 0) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  void _handleWsMessage(WsInboundMessage msg) {
    switch (msg.type) {
      case 'NEW_MESSAGE':
        final m = Message.fromJson(
          msg.data,
          currentUserId: _currentUser.userId,
        );
        _messages[m.conversationId] ??= [];
        final existingIdx = _messages[m.conversationId]!.indexWhere(
          (x) => x.clientId == m.clientId,
        );
        if (existingIdx >= 0) {
          _messages[m.conversationId]![existingIdx] = m;
        } else {
          _messages[m.conversationId]!.add(m);
        }
        _updateConversationLastMessage(m.conversationId, m.content);
        notifyListeners();

      case 'USER_STATUS':
        final userId = msg.data['userId'] as int?;
        final status = msg.data['status'] as String?;
        if (userId == null) return;
        final changed = status == 'online'
            ? _onlineUserIds.add(userId)
            : _onlineUserIds.remove(userId);
        if (changed) notifyListeners();

      case 'PONG':
        break;

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
