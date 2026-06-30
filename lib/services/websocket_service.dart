import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/app_config.dart';
import '../models/chat_models.dart';
import '../data/mock_data.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<WsInboundMessage>.broadcast();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _lastToken;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  static const int _maxAttempts = 6;

  Stream<WsInboundMessage> get stream => _controller.stream;

  void connect(String token) {
    if (_disposed) return;
    _lastToken = token;
    try {
      final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _handleMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
      );
      _reconnectAttempts = 0;
      _startPing();
    } catch (_) {
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
    } catch (_) {}
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
      if (!_disposed && _lastToken != null) connect(_lastToken!);
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
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    if (!_controller.isClosed) _controller.close();
  }
}

class MockWebSocketService extends WebSocketService {
  final _mockController = StreamController<WsInboundMessage>.broadcast();
  Timer? _injectTimer;
  int _activeConvId = 1;

  @override
  Stream<WsInboundMessage> get stream => _mockController.stream;

  @override
  void connect(String token) {
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
