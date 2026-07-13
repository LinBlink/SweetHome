/// Returns the avatar "abbreviation" for a user's display name — used as
/// the letter shown inside the [AvatarWidget] circle when no image is
/// available (see BUGS_TO_FIX.md "如果无法解析出头像，将头像变成 Label
/// 显示"). The rule is locale-agnostic and aims to be sensible for both
/// the Chinese and English name shapes this app actually sees:
///
/// - empty / whitespace-only → `"?"`
/// - single word (typical Chinese, e.g. `"王建国"`) → first character
/// - multiple whitespace-separated words (typical English, e.g.
///   `"John Smith"` or `"Mary Anne Wong"`) → first letter of the first
///   and last word, uppercased (`"JS"`, `"MW"`)
/// - single word with no whitespace → first character, uppercased
String memberAvatarLabel(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  if (!trimmed.contains(RegExp(r'\s'))) {
    return trimmed.substring(0, 1);
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  final first = parts.first.substring(0, 1);
  if (parts.length == 1) return first.toUpperCase();
  final last = parts.last.substring(0, 1);
  return (first + last).toUpperCase();
}