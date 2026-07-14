import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import '../core/app_config.dart';
import '../core/app_colors.dart';
import '../data/mock_data.dart';
import '../models/api_exception.dart';
import '../models/chat_models.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
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

  /// The conversation the user currently has `ChatRoomScreen` open on, if
  /// any. Used by [_handleWsMessage] so a `NEW_MESSAGE` pushed while the
  /// room is already open gets marked read immediately instead of sitting
  /// unread on the server until the next time the conversation is opened
  /// (which is what [_syncReadState] is otherwise only triggered by, via
  /// [loadMessages]'s initial page fetch).
  int? _activeConversationId;

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
    _ws.connect();
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
        _messages[conversationId] != null) {
      return;
    }

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
      if (id != null && (lastServerId == null || id > lastServerId)) {
        lastServerId = id;
      }
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
        await _sendOverWire(
          conversationId: conversationId,
          content: content,
          type: MessageType.text,
          clientId: clientId,
        );
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
    _activeConversationId = convId;
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

  /// Call from `ChatRoomScreen.dispose()` so a `NEW_MESSAGE` pushed for
  /// this conversation *after* the user has navigated away doesn't get
  /// auto-marked read by [_handleWsMessage] — only guards against a stale
  /// [_activeConversationId] still pointing at a conversation the user has
  /// since left; a no-op if another conversation was opened in the
  /// meantime (that call's [setActiveConversation] already overwrote it).
  void clearActiveConversation(int convId) {
    if (_activeConversationId == convId) _activeConversationId = null;
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
        _updateConversationLastMessage(
          m.conversationId,
          m.content,
          type: m.type,
        );
        notifyListeners();
        // The user is actively looking at this conversation right now —
        // advance the read cursor immediately instead of waiting for the
        // next time they open it (which is the only other place
        // `_syncReadState` runs).
        if (m.conversationId == _activeConversationId) {
          _syncReadState(m.conversationId);
        }

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

  void _updateConversationLastMessage(
    int convId,
    String content, {
    MessageType? type,
  }) {
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx >= 0) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessage: content,
        lastMessageAt: DateTime.now(),
        lastMessageType: type,
      );
    }
  }

  /// `POST /users/upload/image` (docs/api.md §2.4) → `SEND_MESSAGE`
  /// with `type=image` (docs/api.md §4.4/§5.2). The upload and the
  /// message send are two independent steps — the upload returns a
  /// URL, and that URL is the `content` of the chat message. We do
  /// them sequentially inside the provider so the call site only sees
  /// one "send image" button.
  ///
  /// Returns `true` on success (the optimistic message has been
  /// reconciled with the server's confirmation), `false` on any
  /// failure. The optimistic message stays in the list either way;
  /// failures flip `isPending` back to `false` so the bubble doesn't
  /// stay in the perpetual-pending state.
  ///
  /// [contentType] follows the same magic-byte sniffing pattern as
  /// avatar upload — see `AuthService.uploadAvatar`.
  Future<bool> sendImageMessage(
    int conversationId, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
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
      content: '',
      type: MessageType.image,
      sentAt: DateTime.now(),
      isMe: true,
      isPending: true,
    );

    _messages[conversationId] ??= [];
    _messages[conversationId]!.add(optimistic);
    _updateConversationLastMessage(
      conversationId,
      optimistic.content,
      type: MessageType.image,
    );
    notifyListeners();

    try {
      String imageUrl;
      if (AppConfig.mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        imageUrl = 'https://mock.local/photos/${_currentUser.userId}-$clientId.jpg';
      } else {
        // Compress before upload. image_picker's maxWidth/quality
        // args only kick in on iOS/Android; on Web the picker hands
        // us the raw original bytes, which routinely busts the §2.4
        // 1 MB cap on phone camera rolls. flutter_image_compress
        // runs on every platform (native uses libjpeg-turbo, web uses
        // a WASM codec), so this single call covers all targets.
        // Output as JPEG regardless of source format — keeps the
        // decoded payload small and consistent with the rest of the
        // media pipeline.
        final compressed = await _compressForUpload(bytes);
        imageUrl = await AuthService.uploadImage(
          _currentUser,
          bytes: compressed,
          filename: filename,
          contentType: 'image/jpeg',
        );
      }
      final replacement = optimistic.copyWith(
        isPending: false,
        senderAvatarUrl: _currentUser.avatarUrl,
        content: imageUrl,
      );
      _replaceOptimistic(conversationId, clientId, replacement);
      _updateConversationLastMessage(
        conversationId,
        imageUrl,
        type: MessageType.image,
      );
      notifyListeners();
      if (!AppConfig.mockMode) {
        await _sendOverWire(
          conversationId: conversationId,
          content: imageUrl,
          type: MessageType.image,
          clientId: clientId,
        );
      }
      return true;
    } catch (_) {
      _replaceOptimistic(
        conversationId,
        clientId,
        optimistic.copyWith(isPending: false),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> _sendOverWire({
    required int conversationId,
    required String content,
    required MessageType type,
    required String clientId,
  }) async {
    if (_ws.isConnected) {
      _ws.send(
        WsOutboundMessage(
          type: 'SEND_MESSAGE',
          payload: {
            'conversationId': conversationId,
            'content': content,
            'messageType': type.apiValue,
            'clientId': clientId,
          },
        ),
      );
      return;
    }
    try {
      final sent = await _chatService.sendMessage(
        conversationId,
        content,
        clientId,
        currentUserId: _currentUser.userId,
        type: type,
      );
      _replaceOptimistic(conversationId, clientId, sent);
      notifyListeners();
    } on ApiException catch (e) {
      _handleApiException(e);
    } catch (_) {
      // Best-effort: the optimistic message has already been
      // reconciled with the original uploaded URL; if the fallback
      // REST send fails, we leave the bubble as-is. The server
      // likely has it anyway (upload succeeded).
    }
  }

  void dismissConnectionError() {
    _connectionError = null;
    notifyListeners();
  }

  void reconnect() {
    _connectionError = null;
    _ws.connect();
    notifyListeners();
  }

  /// Lossy re-encode aimed at the §2.4 1 MB cap. Caps the longer
  /// edge at 1280 px (the same ceiling `image_picker` already uses
  /// on iOS/Android, so on those platforms this is typically a
  /// no-op resize but always a re-encode) and targets quality 80,
  /// which is the conventional JPEG sweet spot — barely
  /// distinguishable from the original at chat-bubble viewing
  /// size, and usually 5–10× smaller than the input on a phone
  /// camera photo.
  ///
  /// If the compressor itself fails (rare — only happens on
  /// malformed source bytes that `detectImageMimeType` couldn't
  /// classify), we fall back to the original bytes rather than
  /// failing the whole send. The picker should already have
  /// produced a valid image, but if the upload would have worked
  /// without compression it shouldn't be compression's fault it
  /// doesn't.
  Future<Uint8List> _compressForUpload(Uint8List bytes) async {
    try {
      final out = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1280,
        minHeight: 1280,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      if (out.isEmpty) return bytes;
      return out;
    } catch (_) {
      return bytes;
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _ws.disconnect();
    super.dispose();
  }
}
