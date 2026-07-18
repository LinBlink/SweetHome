import '../models/chat_models.dart';
import 'chat_local_cache.dart';

/// Result of building a transcript — the rendered text plus counts
/// for the summary line, so the screen doesn't need to re-walk the
/// cache just to show "N conversations, M messages".
class ChatExportResult {
  final String text;
  final int conversationCount;
  final int messageCount;

  const ChatExportResult({
    required this.text,
    required this.conversationCount,
    required this.messageCount,
  });
}

/// Turns the locally-cached chat history (`ChatLocalCache` — the same
/// on-device blob the conversation list reads for offline/instant
/// load) into a plain-text transcript the user can copy or save.
/// Deliberately text, not JSON: this is for a person to read or hand
/// to someone else, not for re-importing into the app.
class ChatExportService {
  const ChatExportService();

  /// [meLabel]/[imageLabel]/[voiceLabel]/[systemLabel] are passed in
  /// (rather than read from `AppLocalizations` here) so this stays a
  /// plain data transform with no `BuildContext` dependency — the
  /// caller already has an `l10n` instance from its widget tree.
  Future<ChatExportResult?> buildTranscript({
    required int currentUserId,
    required String meLabel,
    required String imageLabel,
    required String voiceLabel,
  }) async {
    final data = await ChatLocalCache().load(currentUserId: currentUserId);
    if (data == null) return null;

    var messageCount = 0;
    var conversationCount = 0;
    final buffer = StringBuffer();
    for (final conv in data.conversations) {
      final messages = data.messagesByConversation[conv.id] ?? const <Message>[];
      if (messages.isEmpty) continue;
      conversationCount++;
      buffer.writeln('==== ${conv.name} ====');
      buffer.writeln();
      for (final m in messages) {
        messageCount++;
        final sender = m.isMe ? meLabel : m.senderName;
        final content = switch (m.type) {
          MessageType.image => imageLabel,
          MessageType.voice => voiceLabel,
          MessageType.text || MessageType.system => m.content,
        };
        buffer.writeln('[${_formatTime(m.sentAt)}] $sender: $content');
      }
      buffer.writeln();
    }
    if (conversationCount == 0) return null;

    return ChatExportResult(
      text: buffer.toString().trimRight(),
      conversationCount: conversationCount,
      messageCount: messageCount,
    );
  }

  String _formatTime(DateTime utc) {
    final t = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
