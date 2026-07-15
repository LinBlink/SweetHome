import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final repoRoot = Platform.environment['REPO_ROOT'] ?? '.';
  final manifest = File('$repoRoot/scripts/publish_moment_fix_strings.json');
  final manifestData =
      jsonDecode(manifest.readAsStringSync()) as List<dynamic>;
  final dir = Directory('$repoRoot/lib/l10n');
  final files = {
    'en': File('${dir.path}/app_en.arb'),
    'zh': File('${dir.path}/app_zh.arb'),
    'zh_Hans': File('${dir.path}/app_zh_Hans.arb'),
    'zh_Hant': File('${dir.path}/app_zh_Hant.arb'),
    'ja': File('${dir.path}/app_ja.arb'),
    'ko': File('${dir.path}/app_ko.arb'),
    'my': File('${dir.path}/app_my.arb'),
  };

  for (final localeEntry in files.entries) {
    final file = localeEntry.value;
    final content = file.readAsStringSync();
    final finalBraceIndex = content.lastIndexOf('}');
    if (finalBraceIndex < 0) {
      print('No trailing } in ${file.path}; skipping');
      continue;
    }

    final insertion = StringBuffer();
    final isLastIndex = manifestData.length - 1;
    for (var i = 0; i < manifestData.length; i++) {
      final isLast = i == isLastIndex;
      final entry = manifestData[i];
      final m = entry as Map<String, dynamic>;
      final key = m['key'] as String;
      final values =
          (m['values'] as Map<String, dynamic>).cast<String, dynamic>();
      final placeholders = m['placeholders'] as Map<String, dynamic>?;
      final value = (values[localeEntry.key] ?? values['en']) as String;
      if (placeholders != null) {
        final ph = placeholders.entries.first;
        insertion.write(
          '"@${key}": {\n    "placeholders": {\n        "${ph.key}": ${jsonEncode(ph.value)}\n    }\n},\n',
        );
      }
      insertion.write('"$key": "${escape(value)}"');
      if (!isLast) insertion.write(',');
      insertion.write('\n');
    }

    final before = content.substring(0, finalBraceIndex);
    final after = content.substring(finalBraceIndex);
    final trimmed = before.trimRight();
    final needsComma = !trimmed.endsWith(',') && !trimmed.endsWith('{');
    final sep = needsComma ? ',' : '';
    final newContent =
        '$before$sep${insertion.toString()}$after';
    file.writeAsStringSync(newContent);
  }
  print('done');
}

String escape(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n');
