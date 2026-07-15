import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/l10n/app_localizations.dart';
import 'package:sweethome_flutter/widgets/emoji_picker.dart';

// Tests for the curated emoji picker. The data is private, so we
// exercise the widget tree instead of poking the lists directly.
// Coverage goals:
//   1. Renders exactly 8 category tabs (one per curated category).
//   2. Tapping a category tab changes the grid contents.
//   3. Tapping an emoji invokes the callback with that character.

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('EmojiPicker widget', () {
    testWidgets('renders 8 category tabs', (tester) async {
      await tester.pumpWidget(_wrap(EmojiPicker(onEmojiSelected: (_) {})));
      await tester.pumpAndSettle();
      // 8 categories × 1 Tooltip each → 8 tooltips.
      expect(find.byType(Tooltip), findsNWidgets(8));
    });

    testWidgets('tapping an emoji invokes the callback', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _wrap(EmojiPicker(onEmojiSelected: (e) => picked = e)),
      );
      await tester.pumpAndSettle();
      // 😀 appears twice in the tree — once in the grid cell
      // (size 24) and once in the category tab (size 20). We
      // want the grid one, so filter by font size.
      final gridSmiley = find.byWidgetPredicate(
        (w) => w is Text && w.data == '😀' && w.style?.fontSize == 24,
      );
      expect(gridSmiley, findsOneWidget);
      await tester.tap(gridSmiley);
      await tester.pump();
      expect(picked, '😀');
    });

    testWidgets('switching category reveals new emoji', (tester) async {
      await tester.pumpWidget(_wrap(EmojiPicker(onEmojiSelected: (_) {})));
      await tester.pumpAndSettle();
      // 👋 is in the People category (not the Smiley category).
      // The category-tab icon is always rendered (size 20), so
      // filter to grid cells (size 24) to assert the grid contents.
      bool peopleGridHasWave() => find
          .byWidgetPredicate(
            (w) => w is Text && w.data == '👋' && w.style?.fontSize == 24,
          )
          .evaluate()
          .isNotEmpty;
      expect(peopleGridHasWave(), isFalse);
      final tooltips = find.byType(Tooltip);
      await tester.tap(tooltips.at(1));
      await tester.pumpAndSettle();
      expect(peopleGridHasWave(), isTrue);
    });
  });
}