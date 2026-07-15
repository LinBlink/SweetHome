import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// CI guard: fails if any hardcoded Chinese / Japanese / Korean
/// text is added to a UI `Text(...)` widget, AppBar title, or
/// similar user-visible surface — i.e. anywhere a developer
/// forgot to route through `AppLocalizations.of(context)!.<key>`.
///
/// Allowed: the `lib/l10n/*.arb` translation tables (they ARE the
/// Chinese/Japanese/Korean text, by design), the `mock_data.dart`
/// fixture (user names + chat content for mock mode), the
/// `kinship/terms/*.dart` per-locale term tables, the
/// `language_picker.dart` (each language's own-script name), the
/// `core/time/app_time_formatter.dart` (zh-locale date patterns like
/// `M月d日` — intl's `MMMd` symbol drops the `日` suffix once a time
/// field is appended, so the literal pattern is used instead), and
/// comments.
///
/// If this test ever fails, the fix is one of:
///   1. Add a key to every locale's `lib/l10n/app_*.arb` and
///      replace the hardcoded string with `l10n.<newKey>`.
///   2. If the string is a debug-only / dev-tool surface, gate
///      the test file with the `kIsDebug` guard.
void main() {
  test('no hardcoded CJK strings in non-arb user-visible code', () {
    final offenders = <String>[];
    final libDir = Directory('lib');
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      // Skip the things that are *supposed* to be in CJK:
      if (path.contains('/l10n/')) continue;
      if (path.contains('/kinship/terms/')) continue;
      if (path.contains('mock_data.dart')) continue;
      if (path.contains('countries.dart')) continue;
      // `language_picker.dart` shows each language's name in its
      // OWN script by design (e.g. '简体中文' for zh-Hans, '日本語'
      // for ja). That's standard i18n practice — a Japanese user
      // picker should label Japanese in Japanese, not English.
      if (path.contains('language_picker.dart')) continue;
      // `app_time_formatter.dart` embeds zh-locale date patterns
      // (`M月d日` / `M月d日 HH:mm`) as DateFormat patterns. These are
      // locale-natural formatting tokens, not translatable UI text —
      // intl's built-in `MMMd` symbol drops the `日` suffix when a
      // time field is appended, so the literal is unavoidable.
      if (path.contains('core/time/app_time_formatter.dart')) continue;
      // Skip generated files.
      if (path.endsWith('.g.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_isHardcodedUserVisibleCjk(path, line, i, lines)) {
          offenders.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Hardcoded CJK strings in non-arb code — route these '
          'through l10n.<key>:\n${offenders.join("\n")}',
    );
  });
}

/// Returns true if [line] is a user-visible CJK string that
/// should have been routed through `AppLocalizations.of(context)`.
///
/// Heuristic: the line must contain at least one CJK character
/// AND match one of the user-visible UI patterns AND not be
/// inside a `//` / `///` / `*` comment AND not be a `l10n.<key>`
/// reference. False positives are acceptable; the goal is to
/// catch new occurrences of a bug we've fixed several times.
bool _isHardcodedUserVisibleCjk(
  String path,
  String line,
  int index,
  List<String> lines,
) {
  if (!line.contains(_cjkPattern)) return false;
  // Strip a trailing `// ...` comment so that code+comment lines
  // (e.g. `final String s; // 我 喜欢`) only match the CJK in the
  // code part, not in the comment part.
  final codeOnly = _stripTrailingComment(line);
  if (!codeOnly.contains(_cjkPattern)) return false;
  // Skip pure comment lines.
  final trimmed = codeOnly.trimLeft();
  if (trimmed.startsWith('//')) return false;
  if (trimmed.startsWith('///')) return false;
  if (trimmed.startsWith('*')) return false;
  // Skip if the previous line is a `///` doc comment (we're inside
  // a multi-line doc block).
  if (index > 0 && lines[index - 1].trimLeft().startsWith('///')) {
    return false;
  }
  // Skip lines that are reading from a l10n getter.
  if (line.contains('l10n.')) return false;
  // Skip lines with `$` interpolation (these are typically template
  // expressions on user-visible strings, which we'll already flag
  // upstream when the format arg is in CJK).
  if (line.contains(_userVisiblePattern)) {
    return true;
  }
  return false;
}

/// Trim any `// ...` line comment off the end of [line]. Naive but
/// sufficient: looks for the first `//` that isn't inside a string
/// literal and isn't a `://` (URL scheme). Good enough for the
/// patterns we use in this repo.
String _stripTrailingComment(String line) {
  // Quick bail-outs: if the line is wholly a comment, return as-is
  // and let the upstream `startsWith('//')` filter handle it.
  if (line.trimLeft().startsWith('//')) return line;
  // Find the first `//` that isn't preceded by a colon (i.e. not
  // `://` from a URL) and isn't inside a string literal. For our
  // use this is approximate — we only need to skip the trailing
  // comment, not perfectly parse Dart syntax.
  final idx = _findCommentStart(line);
  if (idx < 0) return line;
  return line.substring(0, idx).trimRight();
}

int _findCommentStart(String line) {
  var inString = false;
  var stringChar = '';
  for (var i = 0; i < line.length - 1; i++) {
    final c = line[i];
    if (inString) {
      if (c == '\\') {
        i++; // skip escaped char
        continue;
      }
      if (c == stringChar) inString = false;
      continue;
    }
    if (c == '"' || c == "'") {
      inString = true;
      stringChar = c;
      continue;
    }
    if (c == '/' && line[i + 1] == '/') {
      // Skip `://` (URL scheme / protocol).
      if (i > 0 && line[i - 1] == ':') continue;
      return i;
    }
  }
  return -1;
}

final _cjkPattern = RegExp(r'[\u4e00-\u9fff\u3040-\u309f\u30a0-\u30ff\uac00-\ud7af]');
final _userVisiblePattern = RegExp(
  r"""(\bText\(|labelText:|tooltip:|hintText:|helperText:|title:|'[^']*[\u4e00-\u9fff]|[^,]\s*['"][\u4e00-\u9fff]+['"])""",
);
