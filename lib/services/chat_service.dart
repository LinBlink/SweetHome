import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/chat_models.dart';

class ChatService {
  final String _token;
  ChatService(this._token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<List<Conversation>> fetchConversations() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/conversations'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200) throw Exception(body['message']);
    final list = body['data'] as List<dynamic>;
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
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200) throw Exception(body['message']);
    final data = body['data'] as Map<String, dynamic>;
    final msgs = (data['messages'] as List<dynamic>)
        .map((e) => Message.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
    return (
      messages: msgs,
      hasMore: data['hasMore'] as bool? ?? false,
      nextCursor: data['nextCursor'] as int?,
    );
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
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 && resp.statusCode != 201) throw Exception(body['message']);
    return Message.fromJson(body['data'] as Map<String, dynamic>, currentUserId: currentUserId);
  }
}
