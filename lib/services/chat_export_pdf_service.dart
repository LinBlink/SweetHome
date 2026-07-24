import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  ChatExportPdfService();

  /// Cache for the emoji→PNG renderings so a chat full of the same
  /// "❤️" doesn't re-render the same glyph a hundred times.
  final Map<String, Uint8List> _emojiImageCache = <String, Uint8List>{};

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
      case MessageType.redpacket:
        // §9 — red packet card. Export the localized "[Red Packet]"
        // label rather than the raw id string (per the same
        // "服务端只给结构化数据" principle the in-app bubble follows).
        return pw.Text(
          '[${m.content}]',
          style: const pw.TextStyle(fontSize: 11),
        );
      case MessageType.text:
      case MessageType.system:
        return _renderTextWithEmoji(m.content, fontSize: 11);
    }
  }

  // ── Emoji-as-image rendering ───────────────────────────────────────
  //
  // The bundled `NotoEmoji-Regular.ttf` is the COLOR variant (its
  // TTF tables include COLR / CPAL / SVG-in-OT). The `pdf` package's
  // TTF parser only handles standard outline (`glyf`) glyphs, so any
  // emoji code point that exists only in color tables comes out as
  // missing-glyph rectangles — which is what a chat message full of
  // "❤️👍😊" looks like today.
  //
  // Workaround: walk the message text, split it into runs of plain
  // text and runs of emoji code points (including ZWJ sequences like
  // 👨‍👩‍👧 that the standard emoji test range misses), render each
  // emoji run as a PNG via Flutter's own `TextPainter` (which uses
  // the OS / web-bundled color emoji font and DOES render correctly),
  // then assemble the result as a `pw.RichText` with `TextSpan` for
  // plain runs and `WidgetSpan` for the inline PNGs. The PNGs are
  // cached so a long chat of repeated emoji doesn't re-render the
  // same glyph a hundred times.

  /// Matches a single emoji cluster: one base pictographic codepoint
  /// plus optional variation selector (`\u{FE0F}`) and any ZWJ-
  /// joined follow-up pictographics. The ranges below cover every
  /// emoji block currently defined; `\p{Extended_Pictographic}` would
  /// be more accurate but Dart's RegExp engine doesn't expose it
  /// portably, so the explicit ranges stand in.
  static final RegExp _emojiCluster = RegExp(
    '([\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}'
    '\u{1F1E6}-\u{1F1FF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}])'
    '\u{FE0F}?'
    '(\u{200D}([\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}'
    '\u{1F1E6}-\u{1F1FF}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}])'
    '\u{FE0F}?)*',
    unicode: true,
  );

  /// Render [text] as a PDF widget, splitting any emoji runs into
  /// inline images and the rest as a regular `TextSpan`. Pure-text
  /// messages (no emoji) take the fast path and just return
  /// `pw.Text` so the common case doesn't pay for the `RichText`
  /// overhead.
  Future<pw.Widget> _renderTextWithEmoji(
    String text, {
    required double fontSize,
  }) async {
    if (!_emojiCluster.hasMatch(text)) {
      return pw.Text(text, style: pw.TextStyle(fontSize: fontSize));
    }

    final spans = <pw.InlineSpan>[];
    var cursor = 0;
    for (final match in _emojiCluster.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          pw.TextSpan(
            text: text.substring(cursor, match.start),
            style: pw.TextStyle(fontSize: fontSize),
          ),
        );
      }
      final emoji = match.group(0)!;
      // Get-or-create in the cache — `Map.putIfAbsent` is sync, so
      // for the cold-cache path we await the renderer and stash the
      // result. A repeat hit short-circuits.
      Uint8List? png = _emojiImageCache[emoji];
      if (png == null) {
        png = await _renderEmojiToPng(emoji);
        if (png != null) _emojiImageCache[emoji] = png;
      }
      if (png != null) {
        // `WidgetSpan` lets us inline an image at the text baseline;
        // the `FontSize` matches the surrounding text so emoji sits
        // roughly on the cap-height of regular glyphs.
        spans.add(
          pw.WidgetSpan(
            child: pw.SizedBox(
              width: fontSize + 2,
              height: fontSize + 2,
              child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
            ),
          ),
        );
      } else {
        // Render failed — fall back to the raw glyph and let the
        // pdf package print whatever its font can muster. Better a
        // missing-glyph box than a blank spot in the export.
        spans.add(
          pw.TextSpan(
            text: emoji,
            style: pw.TextStyle(fontSize: fontSize),
          ),
        );
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(
        pw.TextSpan(
          text: text.substring(cursor),
          style: pw.TextStyle(fontSize: fontSize),
        ),
      );
    }
    // `pw.RichText.text` is a single `InlineSpan` (the root span),
    // not a list. Wrap the run list in a parent `TextSpan` with
    // `children:` so the layout engine treats it as one block of
    // mixed text + inline images.
    return pw.RichText(text: pw.TextSpan(children: spans));
  }

  /// Render [emoji] as a transparent PNG using Flutter's `TextPainter`,
  /// which honors the platform's color emoji font (Apple Color Emoji
  /// on iOS/macOS, Noto Color Emoji on most Linux/Android, the
  /// browser's bundled font on web). The result is a tightly-cropped
  /// PNG sized to the glyph's measured bounds plus 2px of padding.
  Future<Uint8List?> _renderEmojiToPng(String emoji) async {
    if (emoji.isEmpty) return null;
    const fontSize = 16.0;
    final painter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    if (painter.width <= 0 || painter.height <= 0) return null;

    final w = painter.width.ceil() + 4;
    final h = painter.height.ceil() + 4;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );
    // Center the glyph in the captured area (TextPainter's origin
    // is top-left of the layout box, so 2px padding works out).
    painter.paint(canvas, const Offset(2, 2));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return bytes?.buffer.asUint8List();
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
