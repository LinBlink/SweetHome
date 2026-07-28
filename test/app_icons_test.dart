import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sweethome_flutter/core/app_icons.dart';
import 'package:sweethome_flutter/providers/theme_provider.dart';
import 'package:sweethome_flutter/widgets/app_icon.dart';

/// Guards the custom icon set against the ways it silently rots: a spec
/// whose file was never created, a file nobody references, artwork
/// drawn on the wrong canvas — and, now that the user can switch packs,
/// a pack that only half exists.
void main() {
  Directory dirOf(AppIconPack pack) => Directory(pack.dir);
  File fileOf(AppIconPack pack, AppIconSpec spec) =>
      File('${pack.dir}/${spec.name}.svg');

  group('icon set wiring', () {
    for (final pack in AppIconPack.values) {
      test('every spec has an svg file in ${pack.id}', () {
        final missing = AppIcons.all
            .where((s) => !fileOf(pack, s).existsSync())
            .map((s) => s.name)
            .toList();
        expect(missing, isEmpty,
            reason: 'declared in AppIcons but no file in ${pack.dir}. '
                'Every pack needs every icon — a gap here is an icon '
                'that turns back into a Material glyph the moment the '
                'user picks this pack');
      });

      test('every svg file in ${pack.id} has a spec', () {
        final declared = AppIcons.all.map((s) => s.name).toSet();
        final orphans = dirOf(pack)
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .where((n) => n.endsWith('.svg'))
            .map((n) => n.substring(0, n.length - 4))
            .where((n) => !declared.contains(n))
            .toList();
        expect(orphans, isEmpty,
            reason: 'file on disk that no AppIconSpec points at — either '
                'add a spec or delete the file');
      });

      test('pubspec registers the ${pack.id} directory', () {
        // Directory form, so a new icon needs no pubspec edit. If someone
        // switches this to file-by-file entries, new icons start silently
        // falling back to Material forever.
        expect(File('pubspec.yaml').readAsStringSync(),
            contains('${pack.dir}/'));
      });
    }

    test('spec names are unique', () {
      final names = AppIcons.all.map((s) => s.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('pack ids are unique and stable', () {
      // Ids are the SharedPreferences values — renaming one silently
      // resets everybody who had it selected.
      final ids = AppIconPack.values.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, containsAll(<String>['standard', 'playful']));
      expect(AppIconPack.byId('nonsense'), AppIconPack.standard,
          reason: 'an unknown stored id must fall back, not throw');
    });
  });

  group('artwork', () {
    for (final pack in AppIconPack.values) {
      test('${pack.id} icons use a 24x24 viewBox and no raster/gradient', () {
        // Empty files are the expected placeholder state and are skipped;
        // this only polices files that actually have artwork.
        for (final spec in AppIcons.all) {
          final body = fileOf(pack, spec).readAsStringSync().trim();
          if (body.isEmpty) continue;
          final where = '${pack.dir}/${spec.name}.svg';

          expect(body, contains('viewBox'),
              reason: '$where has no viewBox, so it cannot scale');
          expect(
            RegExp(r'viewBox\s*=\s*"0\s+0\s+24\s+24"').hasMatch(body),
            isTrue,
            reason: '$where must be drawn on a 24x24 canvas',
          );
          for (final banned in [
            '<image',
            'linearGradient',
            'radialGradient',
          ]) {
            expect(body.contains(banned), isFalse,
                reason: '$where uses $banned, which flutter_svg does not '
                    'render reliably');
          }
        }
      });

      test('${pack.id} artwork is tintable or painted, never half of each',
          () {
        // A file that says `currentColor` anywhere is treated as tintable
        // and gets the srcIn filter, which flattens whatever colours the
        // rest of it paints. That loss is silent, so catch it here.
        for (final spec in AppIcons.all) {
          final body = fileOf(pack, spec).readAsStringSync().trim();
          if (body.isEmpty || !body.contains('currentColor')) continue;

          expect(
            RegExp(r'(fill|stroke)\s*=\s*"#').hasMatch(body),
            isFalse,
            reason: '${pack.dir}/${spec.name}.svg mixes currentColor with '
                'literal colours — the literals get tinted away. Use one '
                'or the other.',
          );
        }
      });
    }

    test('the standard pack stays tintable end to end', () {
      // It is the pack that has to follow the theme colour, including
      // the places that only pass a colour (nav bar, danger rows). One
      // painted file in here is one icon that stops matching.
      for (final spec in AppIcons.all) {
        final body =
            fileOf(AppIconPack.standard, spec).readAsStringSync().trim();
        if (body.isEmpty) continue;
        expect(body, contains('currentColor'),
            reason: '${spec.name}.svg in the standard pack paints its own '
                'colours, so it will ignore the tint every call site '
                'passes');
      }
    });
  });

  group('multicolour detection', () {
    test('currentColor artwork is tintable, painted artwork is not', () {
      expect(
        AppIconAssets.isMulticolorSource(
            '<svg><path fill="currentColor"/></svg>'),
        isFalse,
      );
      expect(
        AppIconAssets.isMulticolorSource('<svg><path fill="#F4715C"/></svg>'),
        isTrue,
      );
    });
  });

  group('AppIcon', () {
    tearDown(AppIconAssets.debugReset);

    testWidgets('falls back to the Material icon before warm-up', (t) async {
      AppIconAssets.debugReset();
      await t.pumpWidget(const MaterialApp(
        home: AppIcon(AppIcons.chatSend, size: 20, color: Colors.white),
      ));
      expect(find.byIcon(AppIcons.chatSend.fallback), findsOneWidget);
    });

    testWidgets('an undrawn icon keeps the requested size', (t) async {
      AppIconAssets.debugReset();
      await t.pumpWidget(const MaterialApp(
        home: AppIcon(AppIcons.rowChevron, size: 20),
      ));
      expect(t.widget<Icon>(find.byType(Icon)).size, 20);
    });

    testWidgets('inherits size and colour from IconTheme like Icon does',
        (t) async {
      AppIconAssets.debugReset();
      await t.pumpWidget(const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 17, color: Colors.red),
          child: AppIcon(AppIcons.actionBack),
        ),
      ));
      final icon = t.widget<Icon>(find.byType(Icon));
      expect(icon.size, 17);
      expect(icon.color, Colors.red);
    });

    testWidgets('renders the svg once the file has artwork', (t) async {
      AppIconAssets.debugSetDrawn([AppIcons.chatSend]);
      await t.pumpWidget(const MaterialApp(
        home: AppIcon(AppIcons.chatSend),
      ));
      // No Material glyph anymore — the SVG path took over.
      expect(find.byIcon(AppIcons.chatSend.fallback), findsNothing);
    });

    testWidgets('tints monochrome artwork but not painted artwork',
        (t) async {
      AppIconAssets.debugSetDrawn(
        [AppIcons.chatSend, AppIcons.navHome],
        multicolor: [AppIcons.navHome],
      );
      await t.pumpWidget(const MaterialApp(
        home: Column(children: [
          AppIcon(AppIcons.chatSend, color: Colors.red),
          AppIcon(AppIcons.navHome, color: Colors.red),
        ]),
      ));

      final pictures = t.widgetList<SvgPicture>(find.byType(SvgPicture));
      expect(pictures.first.colorFilter, isNotNull);
      expect(pictures.last.colorFilter, isNull);
    });

    testWidgets('a half-transparent tint still dims painted artwork',
        (t) async {
      AppIconAssets.debugSetDrawn(
        [AppIcons.navHome],
        multicolor: [AppIcons.navHome],
      );
      await t.pumpWidget(MaterialApp(
        // What the unselected nav items pass: brand beige at 80%.
        home: AppIcon(AppIcons.navHome, color: const Color(0xCCEFE0D0)),
      ));

      expect(t.widget<Opacity>(find.byType(Opacity)).opacity,
          closeTo(0.8, 0.01));
    });
  });

  group('icon packs', () {
    tearDown(AppIconAssets.debugReset);

    testWidgets('an icon repaints itself when the pack changes', (t) async {
      // Drawn in the playful pack only, so the switch is visible as
      // fallback -> artwork without touching the widget tree.
      AppIconAssets.debugSetDrawn(
        [AppIcons.chatSend],
        multicolor: [AppIcons.chatSend],
        inPack: AppIconPack.playful,
      );
      await t.pumpWidget(const MaterialApp(home: AppIcon(AppIcons.chatSend)));
      expect(find.byIcon(AppIcons.chatSend.fallback), findsOneWidget);

      AppIconAssets.pack.value = AppIconPack.playful;
      await t.pump();

      expect(find.byIcon(AppIcons.chatSend.fallback), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('the active pack decides which file is loaded', (t) async {
      AppIconAssets.debugSetDrawn([AppIcons.chatSend]);
      AppIconAssets.debugSetDrawn([AppIcons.chatSend],
          inPack: AppIconPack.playful);
      AppIconAssets.pack.value = AppIconPack.playful;

      await t.pumpWidget(const MaterialApp(home: AppIcon(AppIcons.chatSend)));

      final loader =
          t.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader;
      expect((loader as SvgAssetLoader).assetName,
          AppIcons.chatSend.assetPathIn(AppIconPack.playful));
    });

    testWidgets('the choice survives a restart', (t) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'icon_pack': 'playful'});
      final provider = ThemeProvider();
      await provider.restore();
      expect(provider.iconPack, AppIconPack.playful,
          reason: 'a stored pack must be applied before the first frame, '
              'or the app starts on the wrong icons and swaps mid-session');

      await provider.setIconPack(AppIconPack.standard);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('icon_pack'), 'standard');
      provider.dispose();
    });

    testWidgets('a preview can show a pack that is not active', (t) async {
      AppIconAssets.debugSetDrawn([AppIcons.chatSend],
          inPack: AppIconPack.playful);
      // Active pack stays standard, where chatSend is undrawn.
      await t.pumpWidget(MaterialApp(
        home: AppIconArtwork(
          AppIcons.chatSend,
          pack: AppIconPack.playful,
          size: 20,
          color: const Color(0xFF000000),
        ),
      ));

      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });

  // The probe no longer blocks `runApp` (see `AppIconAssets.warmUp` and
  // main.dart): the app paints with Material fallbacks and swaps in the
  // artwork when the probe lands. That swap is the whole point of
  // deferring, and it is invisible in a static test — an icon built
  // *after* warm-up would pass whether or not the notification works.
  // These build first, then warm up, which is the real sequence.
  group('icons swap in when the deferred probe lands', () {
    tearDown(AppIconAssets.debugReset);

    testWidgets('a mounted fallback becomes artwork without a rebuild above it',
        (t) async {
      AppIconAssets.debugReset();
      await t.pumpWidget(const MaterialApp(home: AppIcon(AppIcons.chatSend)));

      // First frame: probe hasn't run, so this is the Material fallback.
      expect(find.byType(SvgPicture), findsNothing);
      expect(t.widget<Icon>(find.byType(Icon)).icon, AppIcons.chatSend.fallback);

      // Probe lands. Nothing above the icon rebuilds — only the
      // notification can drive this.
      AppIconAssets.debugSetDrawn([AppIcons.chatSend]);
      await t.pump();

      expect(find.byType(SvgPicture), findsOneWidget,
          reason: 'the icon kept its Material fallback after the probe '
              'finished — AppIconAssets.revision is not reaching AppIcon, so '
              'deferring warm-up would leave the app on fallbacks forever');
    });

    testWidgets('still tracks pack switches after the swap', (t) async {
      AppIconAssets.debugReset();
      await t.pumpWidget(const MaterialApp(home: AppIcon(AppIcons.chatSend)));

      AppIconAssets.debugSetDrawn([AppIcons.chatSend]);
      AppIconAssets.debugSetDrawn([AppIcons.chatSend],
          inPack: AppIconPack.playful);
      await t.pump();

      AppIconAssets.pack.value = AppIconPack.playful;
      await t.pump();

      final loader = t.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader;
      expect((loader as SvgAssetLoader).assetName,
          AppIcons.chatSend.assetPathIn(AppIconPack.playful),
          reason: 'merging the two listenables must not drop the pack one');
    });
  });
}
