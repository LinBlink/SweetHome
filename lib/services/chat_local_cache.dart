import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_models.dart';

/// Persists received chat history to SharedPreferences so the user
/// can reopen a conversation offline (and so a global search across
/// all conversations doesn't depend on a server round-trip).
///
/// Storage shape: a single JSON blob under [_kBlobKey] with one
/// entry per conversation:
///
/// ```json
/// {
///   "conversations": [
///     { "id": 7, "json": { ...Conversation fields... } },
///     ...
///   ],
///   "messages": [
///     { "conversationId": 7, "messages": [ {...Message...}, ... ] }
///   ]
/// }
/// ```
///
/// Why one blob instead of one key per conversation:
///   - A single `getString` / `setString` is atomic, so a partial
///     write (e.g. process killed mid-flush) never leaves the cache
///     in a half-updated state with mismatched conversation / message
///     entries.
///   - The whole chat dataset is tiny (per-user cap is bounded by
///     conversation count × visible-page-size, well under
///     SharedPreferences' ~1 MB-per-key practical ceiling on every
///     platform we ship to).
///
/// `Message.fromJson` and `Conversation.fromJson` are the inverse
/// of the encoder so an older app version reading a newer blob can
/// fail-soft on unknown fields rather than corrupting existing data.
class ChatLocalCache {
  static const String _kBlobKey = 'chat_cache_v1';

  /// Per-conversation cap on how many messages we keep on disk.
  /// Larger than the typical screen-load (~20) by a comfortable
  /// margin so the chat room opens from cache before the network
  /// round-trip completes. We trim from the *old* end so the most
  /// recent messages survive.
  static const int _messagesPerConversation = 200;

  Future<void> save({
    required List<Conversation> conversations,
    required Map<int, List<Message>> messagesByConversation,
  }) async {
    final convs = conversations
        .map((c) => {'id': c.id, 'json': c.toJsonMap()})
        .toList();
    final msgs = <Map<String, dynamic>>[];
    for (final entry in messagesByConversation.entries) {
      final trimmed = entry.value.length > _messagesPerConversation
          ? entry.value.sublist(entry.value.length - _messagesPerConversation)
          : entry.value;
      msgs.add({
        'conversationId': entry.key,
        'messages': trimmed.map((m) => m.toJson()).toList(),
      });
    }
    final blob = jsonEncode({
      'conversations': convs,
      'messages': msgs,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBlobKey, blob);
  }

  Future<({List<Conversation> conversations, Map<int, List<Message>> messagesByConversation})?>
      load({required int currentUserId}) async {
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(_kBlobKey);
    if (blob == null || blob.isEmpty) return null;
    try {
      final decoded = jsonDecode(blob) as Map<String, dynamic>;
      final convsJson = (decoded['conversations'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final conversations = convsJson
          .map((e) => Conversation.fromJson(e['json'] as Map<String, dynamic>))
          .toList();
      final messagesByConversation = <int, List<Message>>{};
      final msgsJson = (decoded['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final entry in msgsJson) {
        final cid = entry['conversationId'] as int;
        final list = (entry['messages'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((m) => Message.fromJson(m, currentUserId: currentUserId))
            .toList();
        messagesByConversation[cid] = list;
      }
      return (conversations: conversations, messagesByConversation: messagesByConversation);
    } catch (_) {
      // Blob is corrupted (different app version, truncated write,
      // etc.). Drop it rather than crashing on every cold start.
      await prefs.remove(_kBlobKey);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBlobKey);
  }

  /// UTF-8 byte length of the stored blob, for the storage settings
  /// screen's "chat history" row. `0` if nothing has been cached yet.
  Future<int> sizeBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final blob = prefs.getString(_kBlobKey);
    if (blob == null) return 0;
    return utf8.encode(blob).length;
  }
}

extension on Conversation {
  Map<String, dynamic> toJsonMap() => {
        'id': id,
        'name': name,
        'type': isGroup ? 'group' : 'direct',
        'avatarLabel': avatarLabel,
        'avatarColor': avatarColor.toARGB32().toRadixString(16).padLeft(8, '0'),
        'avatarUrl': avatarUrl,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'unreadCount': unreadCount,
        'memberCount': memberCount,
        'relationCode': relationCode,
        'otherUserGender': otherUserGender?.name,
        'otherUserId': otherUserId,
        'lastMessageType': lastMessageType.apiValue,
      };
}