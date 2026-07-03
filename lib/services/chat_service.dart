import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/chat_models.dart';
import 'api_client.dart';

class ChatService {
  final String Function() _tokenProvider;
  ChatService(this._tokenProvider);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_tokenProvider()}',
      };

  Future<List<Conversation>> fetchConversations() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/conversations'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final list = ApiClient.unwrap(resp) as List<dynamic>;
    return list.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<({List<Message> messages, bool hasMore, int? nextCursor})> fetchMessages(
    int conversationId, {
    int? before,
    int limit = 50,
    required int currentUserId,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/conversations/$conversationId/messages'
      '?limit=$limit${before != null ? '&before=$before' : ''}',
    );
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    final msgs = (data['messages'] as List<dynamic>)
        .map((e) => Message.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
    return (
      messages: msgs,
      hasMore: data['hasMore'] as bool? ?? false,
      nextCursor: data['nextCursor'] as int?,
    );
  }

  Future<Conversation> createDirectConversation(int targetUserId) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/conversations'),
          headers: _headers,
          body: jsonEncode({'targetUserId': targetUserId}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  Future<void> markRead(int conversationId, int lastReadMessageId) async {
    await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/conversations/$conversationId/read'),
          headers: _headers,
          body: jsonEncode({'lastReadMessageId': lastReadMessageId}),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<Message> sendMessage(
    int conversationId,
    String content,
    String clientId, {
    required int currentUserId,
  }) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/conversations/$conversationId/messages'),
          headers: _headers,
          body: jsonEncode({'content': content, 'type': 'text', 'clientId': clientId}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return Message.fromJson(data, currentUserId: currentUserId);
  }
}
