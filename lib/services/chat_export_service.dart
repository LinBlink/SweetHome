import '../models/chat_models.dart';
import 'chat_local_cache.dart';

/// One selectable row in the export screen's conversation picker.
class ChatExportConversationSummary {
  final int id;
  final String name;
  final int messageCount;

  const ChatExportConversationSummary({
    required this.id,
    required this.name,
    required this.messageCount,
  });
}

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
/// load) into a plain-text transcript the user can copy, save, or
/// share. Deliberately text, not JSON: this is for a person to read
/// or hand to someone else, not for re-importing into the app.
///
/// See `ChatExportPdfService` for the image-carrying PDF alternative.
class ChatExportService {
  const ChatExportService();

  /// Lists every cached conversation that has at least one message,
  /// for the export screen's "which conversations?" picker. Empty
  /// conversations are excluded since there'd be nothing to export.
  Future<List<ChatExportConversationSummary>> loadConversationSummaries({
    required int currentUserId,
  }) async {
    final data = await ChatLocalCache().load(currentUserId: currentUserId);
    if (data == null) return const [];
    final out = <ChatExportConversationSummary>[];
    for (final conv in data.conversations) {
      final messages = data.messagesByConversation[conv.id] ?? const <Message>[];
      if (messages.isEmpty) continue;
      out.add(ChatExportConversationSummary(
        id: conv.id,
        name: conv.name,
        messageCount: messages.length,
      ));
    }
    return out;
  }

  /// [meLabel]/[imageLabel]/[voiceLabel]/[videoLabel] are passed in
  /// (rather than read from `AppLocalizations` here) so this stays a
  /// plain data transform with no `BuildContext` dependency — the
  /// caller already has an `l10n` instance from its widget tree.
  ///
  /// [conversationIds] restricts the export to that subset — pass the
  /// full set of a user's conversation ids to export everything.
  /// [startDate]/[endDate] further restrict it to messages sent on or
  /// between those local calendar days (inclusive); leave both null
  /// for no date filtering.
  Future<ChatExportResult?> buildTranscript({
    required int currentUserId,
    required Set<int> conversationIds,
    DateTime? startDate,
    DateTime? endDate,
    required String meLabel,
    required String imageLabel,
    required String voiceLabel,
    required String videoLabel,
  }) async {
    final data = await ChatLocalCache().load(currentUserId: currentUserId);
    if (data == null) return null;

    var messageCount = 0;
    var conversationCount = 0;
    final buffer = StringBuffer();
    for (final conv in data.conversations) {
      if (!conversationIds.contains(conv.id)) continue;
      final messages = (data.messagesByConversation[conv.id] ?? const <Message>[])
          .where((m) => _inRange(m.sentAt, startDate, endDate))
          .toList();
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
          MessageType.video => videoLabel,
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

  bool _inRange(DateTime utc, DateTime? startDate, DateTime? endDate) {
    final local = utc.toLocal();
    final date = DateTime(local.year, local.month, local.day);
    if (startDate != null) {
      final s = DateTime(startDate.year, startDate.month, startDate.day);
      if (date.isBefore(s)) return false;
    }
    if (endDate != null) {
      final e = DateTime(endDate.year, endDate.month, endDate.day);
      if (date.isAfter(e)) return false;
    }
    return true;
  }

  String _formatTime(DateTime utc) {
    final t = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
