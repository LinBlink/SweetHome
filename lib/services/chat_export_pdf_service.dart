import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/chat_models.dart';
import 'chat_local_cache.dart';

class ChatExportPdfResult {
  final Uint8List bytes;
  final int conversationCount;
  final int messageCount;

  const ChatExportPdfResult({
    required this.bytes,
    required this.conversationCount,
    required this.messageCount,
  });
}

/// PDF counterpart to `ChatExportService` — same locally-cached chat
/// history, rendered with image messages actually embedded (the
/// reason to pick PDF over the plain-text export in the first
/// place), one page-flow section per conversation.
///
/// CJK text needs a bundled font — the `pdf` package draws its own
/// glyphs and has no access to the OS's system font. Fonts live under
/// `assets/fonts/` (see the README there) and are declared in
/// `pubspec.yaml`; [_loadFonts] loads whichever of them are present
/// and wires the rest in as `fontFallback` so a chat mixing scripts
/// (e.g. a Chinese sender name next to Korean message content, or
/// plain text next to an emoji) doesn't need the caller to know in
/// advance which one to pick. If none load, this falls back to the
/// package's built-in Latin-only font — PDFs still generate with
/// images intact but CJK/emoji text won't render correctly.
class ChatExportPdfService {
  const ChatExportPdfService();

  /// Base font first, in the order a mixed-script fallback chain
  /// should try them. Simplified Chinese is this app's default locale
  /// (see `kDefaultKinshipLocale`), so it goes first. The emoji font
  /// goes last — it only carries emoji glyphs, so it's never the
  /// right *first* choice, only a fallback for codepoints none of the
  /// language fonts cover. It's the monochrome Noto **Emoji** (not
  /// the "Color" variant) because the `pdf` package's TTF parser
  /// renders standard TrueType outline (`glyf`) glyphs reliably, while
  /// COLR/CPAL/CBDT color formats need special handling that the
  /// parser's limited bitmap path doesn't always handle correctly.
  static const _fontAssets = [
    'assets/fonts/NotoSansSC-Regular.ttf',
    'assets/fonts/NotoSansTC-Medium.ttf',
    'assets/fonts/NotoSansJP-Regular.ttf',
    'assets/fonts/NotoSansKR-Regular.ttf',
    'assets/fonts/NotoSansMyanmar-Regular.ttf',
    'assets/fonts/NotoEmoji-Regular.ttf',
  ];

  /// [startDate]/[endDate] restrict the export to messages sent on or
  /// between those local calendar days (inclusive); pass both null to
  /// export every cached message. [onProgress] is called after each
  /// message is rendered (`current` out of the filtered `total`) so
  /// the caller can show a progress bar — PDF generation fetches each
  /// image message's bytes over the network, which for a chat with a
  /// lot of photos can take long enough that a plain spinner reads as
  /// hung.
  Future<ChatExportPdfResult?> build({
    required int currentUserId,
    required Set<int> conversationIds,
    DateTime? startDate,
    DateTime? endDate,
    required String meLabel,
    required String imageLabel,
    required String voiceLabel,
    required String videoLabel,
    required String imageLoadFailedLabel,
    void Function(int current, int total)? onProgress,
  }) async {
    final data = await ChatLocalCache().load(currentUserId: currentUserId);
    if (data == null) return null;

    // Filter up front so `onProgress` can report against the true
    // total instead of guessing before we know how many messages
    // actually fall in range.
    final included = <int, List<Message>>{};
    var totalMessages = 0;
    for (final conv in data.conversations) {
      if (!conversationIds.contains(conv.id)) continue;
      final all = data.messagesByConversation[conv.id] ?? const <Message>[];
      final filtered = (startDate == null && endDate == null)
          ? all
          : all
              .where((m) => _inRange(m.sentAt, startDate, endDate))
              .toList();
      if (filtered.isEmpty) continue;
      included[conv.id] = filtered;
      totalMessages += filtered.length;
    }
    if (included.isEmpty) return null;

    final fonts = await _loadFonts();
    final doc = pw.Document(
      theme: fonts.isEmpty
          ? null
          : pw.ThemeData.withFont(
              base: fonts.first,
              bold: fonts.first,
              fontFallback: fonts.skip(1).toList(),
            ),
    );

    var conversationCount = 0;
    var processed = 0;

    for (final conv in data.conversations) {
      final messages = included[conv.id];
      if (messages == null) continue;
      conversationCount++;

      final rows = <pw.Widget>[];
      for (final m in messages) {
        final sender = m.isMe ? meLabel : m.senderName;
        final content = await _renderContent(
          m,
          imageLabel: imageLabel,
          voiceLabel: voiceLabel,
          videoLabel: videoLabel,
          imageLoadFailedLabel: imageLoadFailedLabel,
        );
        processed++;
        onProgress?.call(processed, totalMessages);
        rows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '[${_formatTime(m.sentAt)}] $sender',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 2),
                content,
              ],
            ),
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Header(text: conv.name),
            ...rows,
          ],
        ),
      );
    }

    if (conversationCount == 0) return null;
    return ChatExportPdfResult(
      bytes: await doc.save(),
      conversationCount: conversationCount,
      messageCount: totalMessages,
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

  Future<pw.Widget> _renderContent(
    Message m, {
    required String imageLabel,
    required String voiceLabel,
    required String videoLabel,
    required String imageLoadFailedLabel,
  }) async {
    switch (m.type) {
      case MessageType.image:
        final bytes = await _fetchBytes(m.content);
        if (bytes == null) {
          return pw.Text(
            '[$imageLabel] $imageLoadFailedLabel',
            style: const pw.TextStyle(fontSize: 11),
          );
        }
        return pw.Container(
          constraints: const pw.BoxConstraints(maxHeight: 220, maxWidth: 220),
          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
        );
      case MessageType.voice:
        return pw.Text('[$voiceLabel]', style: const pw.TextStyle(fontSize: 11));
      case MessageType.video:
        return pw.Text('[$videoLabel]', style: const pw.TextStyle(fontSize: 11));
      case MessageType.text:
      case MessageType.system:
        return pw.Text(m.content, style: const pw.TextStyle(fontSize: 11));
    }
  }

  Future<Uint8List?> _fetchBytes(String url) async {
    if (url.isEmpty) return null;
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      return resp.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<List<pw.Font>> _loadFonts() async {
    final fonts = <pw.Font>[];
    for (final asset in _fontAssets) {
      try {
        final data = await rootBundle.load(asset);
        fonts.add(pw.Font.ttf(data));
      } catch (_) {
        // Missing/unbundled — skip it rather than failing the whole
        // export; the remaining fonts (or none) still apply.
      }
    }
    return fonts;
  }

  String _formatTime(DateTime utc) {
    final t = utc.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
