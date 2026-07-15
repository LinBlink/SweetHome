/// Heuristics for "is this text really just emoji?" — used by the
/// chat bubble to render emoji-only messages in a larger font.
///
/// We deliberately avoid a full Unicode-property match here:
///   1. The full UTS #51 emoji-data list is a moving target and
///      changes every Unicode release — keeping a hand-curated
///      table means we control which emoji render larger.
///   2. The bubble uses this only for sizing — a false negative
///      (emoji shown small) is a cosmetic blemish, not a bug.
///
/// The rule is: no ASCII letters/digits (which would make it
/// "real text"), AND at least one rune falls in the common
/// pictographic ranges. ZWJ, variation selectors, and combining
/// marks are allowed (skin-tone modifiers, family ZWJ sequences).
library;

/// True when [text] is purely emoji + whitespace + common
/// punctuation (commas, dots, exclamation marks, hearts, etc.).
/// Returns false for empty strings and for any string that
/// contains a Latin letter, digit, or CJK / Hangul character.
bool isEmojiOnlyText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return false;
  var pictographic = 0;
  var other = 0;
  for (final rune in trimmed.runes) {
    if (_isPictographicRune(rune)) {
      pictographic++;
    } else if (rune == 0x20 ||
        rune == 0x09 ||
        rune == 0x0A ||
        rune == 0x200D) {
      // whitespace + ZWJ (joins emoji sequences) — allowed
    } else if (rune >= 0xFE00 && rune <= 0xFE0F) {
      // variation selectors — allowed
    } else {
      other++;
    }
  }
  return pictographic > 0 && other == 0;
}

bool _isPictographicRune(int r) {
  // Misc Symbols & Pictographs, Emoticons, Transport, Geometric,
  // Supplemental Symbols & Pictographs, Symbols & Pictographs
  // Extended-A — covers the vast majority of user-facing emoji.
  if (r >= 0x1F300 && r <= 0x1FAFF) return true;
  // Misc Symbols (☀-⛿) and Dingbats (✂-➿).
  if (r >= 0x2600 && r <= 0x27BF) return true;
  // Regional Indicator Symbols (🇦-🇿) used in flag sequences.
  if (r >= 0x1F1E6 && r <= 0x1F1FF) return true;
  // Hearts, ornaments, etc. that fall outside the ranges above
  // but appear in the curated picker (✨, ❤, ⭐).
  if (r == 0x2728 || r == 0x2764 || r == 0x2B50) return true;
  return false;
}