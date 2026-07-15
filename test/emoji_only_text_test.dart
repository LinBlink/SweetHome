import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/emoji_only_text.dart';

void main() {
  group('isEmojiOnlyText', () {
    test('returns true for single emoji', () {
      expect(isEmojiOnlyText('😀'), isTrue);
      expect(isEmojiOnlyText('❤️'), isTrue);
      expect(isEmojiOnlyText('👋'), isTrue);
    });

    test('returns true for emoji runs', () {
      expect(isEmojiOnlyText('😀😃😄'), isTrue);
      expect(isEmojiOnlyText('👍 🎉 ✨'), isTrue);
      expect(isEmojiOnlyText('  👨‍👩‍👧‍👦  '), isTrue); // family ZWJ sequence
    });

    test('returns false for mixed text + emoji', () {
      expect(isEmojiOnlyText('hi 👍'), isFalse);
      expect(isEmojiOnlyText('ok 1 👍'), isFalse);
      expect(isEmojiOnlyText('好 👍'), isFalse);
    });

    test('returns false for plain text', () {
      expect(isEmojiOnlyText('hello'), isFalse);
      expect(isEmojiOnlyText('你好'), isFalse);
      expect(isEmojiOnlyText('hello world'), isFalse);
      expect(isEmojiOnlyText('123'), isFalse);
    });

    test('returns false for empty / whitespace', () {
      expect(isEmojiOnlyText(''), isFalse);
      expect(isEmojiOnlyText('   '), isFalse);
      expect(isEmojiOnlyText('\n\t'), isFalse);
    });

    test('returns false for symbols-only (no pictographic)', () {
      // Symbols that aren't in our emoji ranges — bare punctuation
      // should not be promoted to "emoji only" sizing.
      expect(isEmojiOnlyText('!!!'), isFalse);
      expect(isEmojiOnlyText('---'), isFalse);
    });
  });
}