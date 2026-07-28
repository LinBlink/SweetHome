import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// CI guard: every `TextStyle` handed to a bare [TextPainter] — or to a
/// `TextSpan` inside one — has to name a font family.
///
/// A `Text` widget merges its style onto the ambient `DefaultTextStyle`, so
/// `TextStyle(fontSize: 12)` still inherits the bundled family and renders
/// fine. A [TextPainter] merges nothing: it lays out exactly the style it is
/// given. On mobile that is invisible, because the OS supplies a system font.
/// On web it is a permanent request storm:
///
///   * CanvasKit checks a paragraph's codepoints against *only the families
///     that paragraph names*. With none named, everything above U+009F is
///     "missing".
///   * The engine then fetches a Noto font from `fontFallbackBaseUrl` to
///     cover it. We answer 404 there on purpose — the app bundles the
///     coverage it needs (see `web/flutter_bootstrap.js`).
///   * A failed download is not remembered. The same font is re-queued the
///     next time that text is laid out, and finishing a batch — even an
///     all-failed one — broadcasts a font-change message that re-lays out
///     every paragraph in the app, walking straight back into it.
///
/// So one font-less `TextPainter` is an endless loop of 404s, at frame rate
/// if it sits in an animated build. That is exactly what the family tree's
/// `_MarqueeText` did: it measured `member.name` with a raw
/// `TextStyle(fontSize: 12)` on every tick of a repeating animation, and the
/// console filled with `Failed to load font Noto Sans Symbols`. Nothing
/// looked wrong on screen — the `Text` next to it had inherited the family.
///
/// If this test fails, the fix is one of:
///   1. Wrap the style in `AppTheme.ui(...)` — stamps the bundled family
///      and its fallback chain.
///   2. Measure with what the `Text` will actually render with:
///      `DefaultTextStyle.of(context).style.merge(yourStyle)`.
///   3. If the style names a non-bundled family on purpose (`monospace`),
///      add `fontFamilyFallback: AppTheme.uiFontChain` behind it.
void main() {
  test('no TextPainter lays out a style with no font family', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final lines = entity.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('TextPainter(')) continue;

        // The style, if any, lives in the TextSpan a few lines down. Scan
        // to the end of the constructor call — `..layout(` or `);` at the
        // same nesting — which is well inside 25 lines for every call site
        // in this codebase.
        final end = (i + 25).clamp(0, lines.length);
        final block = lines.sublist(i, end).join('\n');
        final body = block.contains('..layout')
            ? block.substring(0, block.indexOf('..layout'))
            : block;

        if (!body.contains('style:')) {
          // No style at all: the painter renders with the framework
          // default, which on web names no family either.
          offenders.add('$path:${i + 1} — TextPainter with no style');
          continue;
        }
        // Only *positively* resolved styles pass. In particular a style
        // forwarded from a caller (`style: widget.style`) does not: that is
        // exactly what `_MarqueeText` did, and the caller two files away was
        // handing it a bare `TextStyle(fontSize: 12)`. "Somebody else
        // probably named a font" is the assumption that caused the bug, so
        // it cannot be the assumption that clears the guard.
        final named = body.contains('fontFamily') ||
            body.contains('AppTheme.ui') ||
            // Resolved against the ambient DefaultTextStyle — i.e. measured
            // with what the `Text` will actually render with, family and all.
            body.contains('DefaultTextStyle') ||
            body.contains('Theme.of(') ||
            RegExp(r'style: _?(measured|resolved|effective)\w*[,)]')
                .hasMatch(body);
        if (!named) {
          offenders.add('$path:${i + 1} — TextPainter style names no font');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These TextPainter styles name no font family. On web that is '
          'an endless loop of 404s against the font fallback URL — see this '
          "file's doc comment for the three ways to fix it:\n"
          '${offenders.join('\n')}',
    );
  });
}
