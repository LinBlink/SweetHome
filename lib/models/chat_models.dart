import 'dart:convert';

import 'package:flutter/material.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/time/backend_time.dart';

enum MessageType {
  text,
  image,
  voice,
  video,
  system;

  /// Maps the API's `messageType` string (`"TEXT"` / `"IMAGE"` / `"VOICE"`
  /// / `"VIDEO"`) to this enum. Case-insensitive; unknown values fall back
  /// to [text]. See docs/api.md §4.3/§5.2.
  ///
  /// NOTE: as of this writing, docs/api.md §5.2 documents the server as
  /// only recognizing `TEXT`/`IMAGE`/`VOICE`/`SYSTEM` for *chat* messages
  /// (unlike §7.1's moment media, which already accepts `image`/`video`/
  /// `audio`) — an unrecognized `messageType` is silently stored/echoed
  /// back as `TEXT`. Sending `VIDEO` here is forward-looking: it renders
  /// correctly for this client's own optimistic bubble, but until the
  /// backend adds first-class `VIDEO` support, a recipient (or this
  /// client after WS/REST reconciliation) may see it degrade to a plain
  /// text bubble containing the raw video URL instead of a video player.
  static MessageType fromApi(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'TEXT':
        return MessageType.text;
      case 'IMAGE':
        return MessageType.image;
      case 'VOICE':
        return MessageType.voice;
      case 'VIDEO':
        return MessageType.video;
      case 'SYSTEM':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  /// Inverse of [fromApi] — wire value for outbound WebSocket frames
  /// (`§5.2` uses uppercase: `TEXT` / `IMAGE` / `VOICE` / `VIDEO` /
  /// `SYSTEM`).
  String get apiValue {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.voice:
        return 'VOICE';
      case MessageType.video:
        return 'VIDEO';
      case MessageType.system:
        return 'SYSTEM';
    }
  }

  /// REST wire value for `§4.4` `POST /conversations/{id}/messages`.
  /// The HTTP path uses **lowercase** (`text` / `image` / `voice` /
  /// `video` / `system`) per `API.md §4.4` — distinct from the
  /// WebSocket path's uppercase `messageType`. Reusing [apiValue] here
  /// would produce `400 INVALID_MESSAGE_TYPE` server-side.
  String get restValue {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.voice:
        return 'voice';
      case MessageType.video:
        return 'video';
      case MessageType.system:
        return 'system';
    }
  }
}

class Conversation {
  final int id;
  final String name;
  final bool isGroup;
  final String avatarLabel;
  final Color avatarColor;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final int memberCount;

  /// Language-neutral relative-to-viewer kinship code for `type=direct`
  /// conversations only (e.g. `"S"`), computed per-request by the backend —
  /// see docs/api.md §4.1/§七. Null for group conversations. Localize with
  /// `relationLabelFor()` at display time — the backend never localizes.
  final String? relationCode;

  /// The other participant's gender, needed to localize [relationCode]
  /// (disambiguates the bare spouse code). `type=direct` only.
  final Gender? otherUserGender;

  /// The other participant's `userId`, `type=direct` conversations only —
  /// used to look up live online status (WS `USER_STATUS`). Null for group
  /// conversations. See docs/api.md §4.1.
  final int? otherUserId;

  /// Last message's type — `text` / `image` / `voice` / `system`
  /// (defaults to `text` when missing). Drives how the conversation
  /// list renders the [lastMessage] preview: raw URL vs. localized
  /// placeholder like "[图片]" / "[Image]". See docs/api.md §4.1.
  final MessageType lastMessageType;

  const Conversation({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.avatarLabel,
    required this.avatarColor,
    this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.memberCount,
    this.relationCode,
    this.otherUserGender,
    this.otherUserId,
    this.lastMessageType = MessageType.text,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      name: json['name'] as String,
      isGroup: json['type'] == 'group',
      // Empty string → `AvatarWidget` falls back to its `?`
      // placeholder, which is locale-neutral. Avoids a hardcoded
      // Chinese character leaking into non-zh locales.
      avatarLabel: json['avatarLabel'] as String? ?? '',
      avatarColor: Color(
          int.parse((json['avatarColor'] as String? ?? 'FFBF5E3B'), radix: 16)),
      avatarUrl: json['avatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      // A freshly created conversation (see docs/api.md §4.2) has no messages
      // yet, so the backend returns a null lastMessageAt — fall back to "now"
      // rather than crashing the parse.
      lastMessageAt: json['lastMessageAt'] != null
          ? parseBackendTime(json['lastMessageAt'] as String)
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      relationCode: json['relationCode'] as String?,
      otherUserGender:
          json['otherUserGender'] != null ? genderFromString(json['otherUserGender'] as String) : null,
otherUserId: json['otherUserId'] as int?,
      lastMessageType: MessageType.fromApi(json['lastMessageType'] as String?),
    );
  }

  Conversation copyWith({
    int? unreadCount,
    String? lastMessage,
    DateTime? lastMessageAt,
    MessageType? lastMessageType,
  }) {
    return Conversation(
      id: id,
      name: name,
      isGroup: isGroup,
      avatarLabel: avatarLabel,
      avatarColor: avatarColor,
      avatarUrl: avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount,
      relationCode: relationCode,
      otherUserGender: otherUserGender,
      otherUserId: otherUserId,
      lastMessageType: lastMessageType ?? this.lastMessageType,
    );
  }
}

class Message {
  final String clientId;
  final int? serverId;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String senderAvatarLabel;
  final String? senderAvatarUrl;
  final Color senderAvatarColor;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isMe;
  final bool isPending;

  /// Sender's language-neutral kinship code relative to the viewing user
  /// (e.g. `"S"`, `"Son"`), computed per-request by the backend — see
  /// docs/api.md §4.3/§5.2/§七. Localize with `relationLabelFor()` at display
  /// time — the backend never localizes. Null for own messages.
  final String? senderRelationCode;

  /// Sender's gender, needed to localize [senderRelationCode] (disambiguates
  /// the bare spouse code).
  final Gender? senderGender;

  const Message({
    required this.clientId,
    this.serverId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarLabel,
    this.senderAvatarUrl,
    required this.senderAvatarColor,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isMe,
    this.isPending = false,
    this.senderRelationCode,
    this.senderGender,
  });

  factory Message.fromJson(Map<String, dynamic> json,
      {required int currentUserId}) {
    final senderId = json['senderId'] as int;
    return Message(
      clientId: json['clientId'] as String? ?? json['id'].toString(),
      serverId: json['id'] as int?,
      conversationId: json['conversationId'] as int,
      senderId: senderId,
      senderName: json['senderName'] as String? ?? '',
      senderAvatarLabel: json['senderAvatarLabel'] as String? ?? '?',
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderAvatarColor: const Color(0xFFBF5E3B),
      content: json['content'] as String,
      // REST §4.3 returns `"type"`, WS §5.2 returns `"messageType"` — accept
      // whichever the current frame carries. Without this fallback an image
      // message loaded from history silently parses as `text` (and renders
      // as a raw-URL text bubble instead of via `_ImageBubble`).
      type: MessageType.fromApi(
        (json['messageType'] ?? json['type']) as String?,
      ),
      sentAt: parseBackendTime(json['sentAt'] as String),
      isMe: senderId == currentUserId,
      senderRelationCode: json['senderRelationCode'] as String?,
      senderGender:
          json['senderGender'] != null ? genderFromString(json['senderGender'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'messageType': type.apiValue,
        'sentAt': sentAt.toIso8601String(),
      };

  Message copyWith({
    int? serverId,
    bool? isPending,
    String? senderAvatarUrl,
    String? content,
    MessageType? type,
  }) =>
      Message(
        clientId: clientId,
        serverId: serverId ?? this.serverId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarLabel: senderAvatarLabel,
        senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
        senderAvatarColor: senderAvatarColor,
        content: content ?? this.content,
        type: type ?? this.type,
        sentAt: sentAt,
        isMe: isMe,
        isPending: isPending ?? this.isPending,
        senderRelationCode: senderRelationCode,
        senderGender: senderGender,
      );
}

class WsOutboundMessage {
  final String type;
  final Map<String, dynamic> payload;
  const WsOutboundMessage({required this.type, required this.payload});

  /// Serializes the frame to a JSON string. Uses [jsonEncode] rather
  /// than hand-rolled string interpolation so quotes, backslashes,
  /// newlines, and control characters in user-supplied `content`
  /// are escaped correctly. A naïve `replaceAll('"', '\\"')` would
  /// emit invalid JSON for any message containing a backslash, a
  /// newline, or an emoji surrogate pair.
  ///
  /// Outbound frames are flat (`type` + payload keys at the top
  /// level), not wrapped in a `data` envelope — only inbound
  /// frames use `data: {...}` (see [WsInboundMessage]).
  String toJsonString() {
    final envelope = <String, dynamic>{
      'type': type,
      ...payload,
    };
    return jsonEncode(envelope);
  }
}

class WsInboundMessage {
  final String type;
  final Map<String, dynamic> data;
  const WsInboundMessage({required this.type, required this.data});
}

/// One row of `ChatProvider.searchMessages` output. A hit is either a
/// [conversation] whose display name matches the query (with [message]
/// = `null`, signalling "open this conversation") or a [message] hit
/// inside an already-cached conversation (with [conversation] populated
/// so the result list can show the avatar + name next to the matched
/// snippet).
class ChatSearchHit {
  final Conversation conversation;
  final Message? message;

  const ChatSearchHit({
    required this.conversation,
    required this.message,
  });
}
