import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/app_config.dart';
import '../models/chat_models.dart';
import '../data/mock_data.dart';

class WebSocketService {
  WebSocketService({required String Function() tokenProvider})
    : _tokenProvider = tokenProvider;

  final String Function() _tokenProvider;
  WebSocketChannel? _channel;
  final _controller = StreamController<WsInboundMessage>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  bool _isConnected = false;
  static const int _maxAttempts = 6;

  Stream<WsInboundMessage> get stream => _controller.stream;

  /// True once the current [_channel] has confirmed a live connection
  /// (via `WebSocketChannel.ready`) and hasn't errored/closed since.
  /// `ChatProvider.sendMessage` checks this before trying a WS send so
  /// a down socket falls back to REST instead of silently no-opping.
  bool get isConnected => _isConnected;

  void connect() {
    if (_disposed) return;
    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=${_tokenProvider()}');
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      channel.stream.listen(
        _handleMessage,
        onError: (_) {
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
      // `WebSocketChannel.connect()` is lazy — success/failure is only
      // known once `ready` completes. Only reset the backoff counter
      // and start pinging on a *confirmed* connection; otherwise every
      // reconnect attempt (success or not) would reset attempts to 0
      // and the exponential backoff below would never advance past 1s.
      unawaited(
        channel.ready
            .then((_) {
              if (_disposed || _channel != channel) return;
              _isConnected = true;
              _reconnectAttempts = 0;
              _startPing();
            })
            .catchError((_) {
              if (_disposed || _channel != channel) return;
              _isConnected = false;
              _scheduleReconnect();
            }),
      );
    } catch (_) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void send(WsOutboundMessage msg) {
    _channel?.sink.add(msg.toJsonString());
  }

  void _handleMessage(dynamic raw) {
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = map['type'] as String;
      final data = map['data'] as Map<String, dynamic>? ?? {};
      _controller.add(WsInboundMessage(type: type, data: data));
    } catch (e) {
      debugPrint('WS message parse failed: $e, raw=$raw');
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _pingTimer?.cancel();
    if (_reconnectAttempts >= _maxAttempts) {
      _controller.add(const WsInboundMessage(
          type: 'ERROR', data: {'code': 'CONNECTION_FAILED', 'message': '连接失败，请检查网络'}));
      return;
    }
    final delay = Duration(
        seconds: (_reconnectAttempts < 5) ? (1 << _reconnectAttempts) : 30);
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send(const WsOutboundMessage(type: 'PING', payload: {}));
    });
  }

  void disconnect() {
    _disposed = true;
    _isConnected = false;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    if (!_controller.isClosed) _controller.close();
  }
}

class MockWebSocketService extends WebSocketService {
  MockWebSocketService() : super(tokenProvider: () => '');

  final _mockController = StreamController<WsInboundMessage>.broadcast();
  Timer? _injectTimer;
  int _activeConvId = 1;

  @override
  Stream<WsInboundMessage> get stream => _mockController.stream;

  @override
  void connect() {
    Future.delayed(const Duration(milliseconds: 400), () {
      _injectTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        final msg = MockDataSource.randomIncomingMessage(_activeConvId);
        _mockController.add(WsInboundMessage(
          type: 'NEW_MESSAGE',
          data: msg.toJson(),
        ));
      });
    });
  }

  @override
  void send(WsOutboundMessage msg) {
    if (msg.type == 'JOIN_CONVERSATION') {
      final id = msg.payload['conversationId'];
      if (id is int) _activeConvId = id;
    }
  }

  @override
  void disconnect() {
    _injectTimer?.cancel();
    if (!_mockController.isClosed) _mockController.close();
  }
}
