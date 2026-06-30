import 'package:flutter/material.dart';

enum MessageType { text, image, voice, system }

class Conversation {
  final int id;
  final String name;
  final bool isGroup;
  final String avatarLabel;
  final Color avatarColor;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final int memberCount;

  const Conversation({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.avatarLabel,
    required this.avatarColor,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.memberCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      name: json['name'] as String,
      isGroup: json['type'] == 'group',
      avatarLabel: json['avatarLabel'] as String? ?? '家',
      avatarColor: Color(
          int.parse((json['avatarColor'] as String? ?? 'FFBF5E3B'), radix: 16)),
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }

  Conversation copyWith({int? unreadCount, String? lastMessage, DateTime? lastMessageAt}) {
    return Conversation(
      id: id,
      name: name,
      isGroup: isGroup,
      avatarLabel: avatarLabel,
      avatarColor: avatarColor,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount,
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
  final Color senderAvatarColor;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final bool isMe;
  final bool isPending;

  const Message({
    required this.clientId,
    this.serverId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarLabel,
    required this.senderAvatarColor,
    required this.content,
    required this.type,
    required this.sentAt,
    required this.isMe,
    this.isPending = false,
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
      senderAvatarColor: const Color(0xFFBF5E3B),
      content: json['content'] as String,
      type: MessageType.text,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isMe: senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'sentAt': sentAt.toIso8601String(),
      };

  Message copyWith({int? serverId, bool? isPending}) => Message(
        clientId: clientId,
        serverId: serverId ?? this.serverId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderAvatarLabel: senderAvatarLabel,
        senderAvatarColor: senderAvatarColor,
        content: content,
        type: type,
        sentAt: sentAt,
        isMe: isMe,
        isPending: isPending ?? this.isPending,
      );
}

class WsOutboundMessage {
  final String type;
  final Map<String, dynamic> payload;
  const WsOutboundMessage({required this.type, required this.payload});

  String toJsonString() {
    final buf = StringBuffer('{');
    buf.write('"type":"$type"');
    payload.forEach((k, v) {
      buf.write(',"$k":');
      if (v is String) {
        buf.write('"${v.replaceAll('"', '\\"')}"');
      } else {
        buf.write('$v');
      }
    });
    buf.write('}');
    return buf.toString();
  }
}

class WsInboundMessage {
  final String type;
  final Map<String, dynamic> data;
  const WsInboundMessage({required this.type, required this.data});
}
