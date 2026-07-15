// One-shot injector for the family-feed l10n block. Reads a UTF-8
// JSON manifest ([scripts/family_feed_strings.json]) and inserts the
// family-feed key/value pair into each `lib/l10n/app_*.arb` file,
// plus the @familyFeedLikeCount placeholder metadata.
//
// Also drops the obsolete `familyFeedComingSoon*` strings — the
// stub screen that used them is being replaced by the real feed, and
// keeping them in the .arb leaks dead strings into the generated
// AppLocalizations surface.

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final manifestRaw =
      File('scripts/family_feed_strings.json').readAsStringSync();
  final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;

  const locales = ['en', 'zh', 'zh_Hans', 'zh_Hant', 'ja', 'ko', 'my'];

  // Line-exact matchers: match the entire line including its trailing
  // newline so adjacent lines' leading whitespace is preserved.
  // `familyFeedComingSoon` does have a trailing comma (more keys
  // follow), `familyFeedComingSoonDesc` does not (it's the LAST key
  // before the obsolete-position `contactsTitle`).
  final obsoleteRe = RegExp(
    r'(?:  "familyFeedComingSoon"[^,\n]*,\n)(?:  "familyFeedComingSoonDesc"[^,\n]*\n)?',
    multiLine: true,
  );

  for (final locale in locales) {
    final values = (manifest[locale] as Map).cast<String, String>();
    final path = 'lib/l10n/app_$locale.arb';
    var content = File(path).readAsStringSync();

    content = content.replaceAll(obsoleteRe, '');

    final insertLines = <String>[];
    for (final entry in values.entries) {
      final encoded = jsonEncode(entry.value);
      final body = encoded.substring(1, encoded.length - 1);
      insertLines.add('  "${entry.key}": "$body",');
    }
    insertLines.add('  "@familyFeedLikeCount": {');
    insertLines.add('    "placeholders": {');
    insertLines.add('      "count": {');
    insertLines.add('        "type": "int"');
    insertLines.add('      }');
    insertLines.add('    }');
    insertLines.add('  },');

    final injection = '\n${insertLines.join('\n')}\n';
    // Strip the trailing comma from the @familyFeedLikeCount
    // metadata block (it's the very last JSON entity we add, and
    // must NOT be followed by a comma before `}`).
    final injectionNormalized =
        injection.replaceFirst(RegExp(r'  \},\n'), '  }\n');
    final trailingRe = RegExp(r'\n\}\s*$');
    final m = trailingRe.firstMatch(content);
    if (m == null) {
      stderr.writeln('No trailing } closing in $path');
      exit(1);
    }
    var head = content.substring(0, m.start);
    if (!head.endsWith(',')) {
      head = '$head,\n';
    } else {
      head = '$head\n';
    }
    File(path).writeAsStringSync('$head$injectionNormalized}\n');
    stdout.writeln(
      'Wrote $path (${File(path).lengthSync()} bytes, +${values.length} keys)',
    );
  }
  stdout.writeln('Done.');
}
