import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A whole interchangeable set of artwork for the same specs.
///
/// Every pack holds the same file names — one `.svg` per [AppIconSpec]
/// — in its own directory, so switching packs is switching a path
/// prefix. A pack is free to be tintable or painted, and free to leave
/// a file empty: both decisions are made per file at warm-up, so a
/// half-drawn pack still runs (the gaps fall back to Material).
enum AppIconPack {
  /// The line-art set. Monochrome and tinted by the call site, so it
  /// follows the theme colour everywhere.
  standard('standard', 'assets/icons/svg'),

  /// The rounder, painted set. Carries its own colours and ignores the
  /// call site's hue — see `assets/icons/README.md`.
  playful('playful', 'assets/icons/svg_playful');

  /// Stable identifier persisted to SharedPreferences. Never rename —
  /// existing prefs entries are keyed on it.
  final String id;

  /// Asset directory, no trailing slash.
  final String dir;

  const AppIconPack(this.id, this.dir);

  static AppIconPack byId(String? id) => values.firstWhere(
        (p) => p.id == id,
        orElse: () => AppIconPack.standard,
      );
}

/// One entry in the custom icon set.
///
/// Every spec pairs the hand-drawn SVG with the Material icon it
/// replaces. The Material icon is not dead weight — it is the live
/// fallback: until the SVG file actually has artwork in it, [AppIcon]
/// renders [fallback] instead. That is what makes the icon set fillable
/// one file at a time without ever shipping a blank square.
@immutable
class AppIconSpec {
  /// Bare file name, no directory and no `.svg` suffix.
  final String name;

  /// Material icon rendered while [name] has no artwork yet.
  final IconData fallback;

  const AppIconSpec(this.name, this.fallback);

  String assetPathIn(AppIconPack pack) => '${pack.dir}/$name.svg';

  @override
  bool operator ==(Object other) =>
      other is AppIconSpec && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'AppIconSpec($name)';
}

/// The custom icon set.
///
/// Names are semantic (what the icon *means* here), not Material's
/// (what it looks like) — `AppIcons.chatSend` rather than
/// `sendRounded` — so a redraw that changes the shape does not leave
/// the name lying. Where two screens genuinely mean the same thing
/// they share one spec; where they merely happen to use the same
/// Material glyph today they get separate specs, so they can diverge
/// later without a rename.
///
/// All artwork is drawn on a 24x24 canvas regardless of the size it is
/// rendered at — see `assets/icons/README.md`.
abstract final class AppIcons {
  // ---- Bottom navigation -------------------------------------------
  // The bar swaps outline for filled on selection, so these come in
  // pairs and the pair must read as the same object in two states.
  static const navMessages =
      AppIconSpec('nav_messages', Icons.chat_bubble_outline);
  static const navMessagesActive =
      AppIconSpec('nav_messages_active', Icons.chat_bubble_rounded);
  static const navContacts =
      AppIconSpec('nav_contacts', Icons.people_alt_outlined);
  static const navContactsActive =
      AppIconSpec('nav_contacts_active', Icons.people_alt_rounded);
  static const navFeed = AppIconSpec('nav_feed', Icons.timeline_outlined);
  static const navFeedActive =
      AppIconSpec('nav_feed_active', Icons.timeline_rounded);
  static const navProfile = AppIconSpec('nav_profile', Icons.person_outline);
  static const navProfileActive =
      AppIconSpec('nav_profile_active', Icons.person_rounded);

  /// The raised centre button — the app's house mark. Only ever drawn
  /// white on the brand gradient, never tinted anything else.
  static const navHome = AppIconSpec('nav_home', Icons.cottage_rounded);

  // ---- Shared chrome -----------------------------------------------
  static const actionBack =
      AppIconSpec('action_back', Icons.arrow_back_ios_new_rounded);
  static const actionSearch =
      AppIconSpec('action_search', Icons.search_rounded);
  static const actionClose = AppIconSpec('action_close', Icons.close_rounded);

  /// Trailing affordance on every tappable settings row.
  static const rowChevron = AppIconSpec('row_chevron', Icons.chevron_right);

  // ---- Chat --------------------------------------------------------
  static const chatSend = AppIconSpec('chat_send', Icons.send_rounded);
  static const chatAttach =
      AppIconSpec('chat_attach', Icons.add_circle_outline);
  static const chatEmoji =
      AppIconSpec('chat_emoji', Icons.emoji_emotions_outlined);
  static const chatKeyboard =
      AppIconSpec('chat_keyboard', Icons.keyboard_alt_outlined);
  static const chatMore = AppIconSpec('chat_more', Icons.more_horiz_rounded);

  // ---- Empty / status states ---------------------------------------
  static const emptyConversations =
      AppIconSpec('empty_conversations', Icons.forum_rounded);
  static const emptySearch =
      AppIconSpec('empty_search', Icons.search_off_rounded);
  static const statusOffline = AppIconSpec('status_offline', Icons.wifi_off);
  static const stateSelected =
      AppIconSpec('state_selected', Icons.check_circle_rounded);

  // ---- Profile -----------------------------------------------------
  static const profileMembers =
      AppIconSpec('profile_members', Icons.people_alt_rounded);
  static const profileJoinFamily =
      AppIconSpec('profile_join_family', Icons.qr_code_2_rounded);
  static const profileTheme =
      AppIconSpec('profile_theme', Icons.palette_rounded);
  static const profileAppearance =
      AppIconSpec('profile_appearance', Icons.dark_mode_rounded);

  /// Entry point for [AppIconPack] — the setting that swaps this very
  /// icon set out from under itself.
  static const profileIconPack =
      AppIconSpec('profile_icon_pack', Icons.auto_awesome_rounded);
  static const profileLanguage =
      AppIconSpec('profile_language', Icons.translate_rounded);
  static const profileStorage =
      AppIconSpec('profile_storage', Icons.delete_sweep_rounded);
  static const profileExport =
      AppIconSpec('profile_export', Icons.ios_share_rounded);
  static const profileEdit = AppIconSpec('profile_edit', Icons.edit_outlined);
  static const profileWallet = AppIconSpec(
      'profile_wallet', Icons.account_balance_wallet_rounded);

  // ---- Appearance picker -------------------------------------------
  static const appearanceAuto =
      AppIconSpec('appearance_auto', Icons.brightness_auto_rounded);
  static const appearanceLight =
      AppIconSpec('appearance_light', Icons.light_mode_rounded);
  static const appearanceDark =
      AppIconSpec('appearance_dark', Icons.dark_mode_rounded);

  /// Every spec, for the warm-up scan and for tooling that wants to
  /// enumerate the set (e.g. a coverage check in tests).
  static const List<AppIconSpec> all = [
    navMessages,
    navMessagesActive,
    navContacts,
    navContactsActive,
    navFeed,
    navFeedActive,
    navProfile,
    navProfileActive,
    navHome,
    actionBack,
    actionSearch,
    actionClose,
    rowChevron,
    chatSend,
    chatAttach,
    chatEmoji,
    chatKeyboard,
    chatMore,
    emptyConversations,
    emptySearch,
    statusOffline,
    stateSelected,
    profileMembers,
    profileJoinFamily,
    profileTheme,
    profileAppearance,
    profileIconPack,
    profileLanguage,
    profileStorage,
    profileExport,
    profileEdit,
    profileWallet,
    appearanceAuto,
    appearanceLight,
    appearanceDark,
  ];
}

/// Tracks which SVGs have artwork in them.
///
/// Deciding this per-frame would mean an async bundle read inside
/// `build`, so instead the whole set is probed once at startup and the
/// answer cached. Before [warmUp] runs — and in widget tests, which
/// never call it — every icon reports "not drawn" and falls back to
/// Material, so nothing can render blank.
abstract final class AppIconAssets {
  static final Set<String> _drawn = <String>{};
  static final Set<String> _multicolor = <String>{};
  static bool _warm = false;

  /// The pack every [AppIcon] draws from.
  ///
  /// A [ValueNotifier] rather than a plain field because switching packs
  /// has to repaint icons scattered across screens that have no other
  /// reason to rebuild — `AppIcon` listens to this directly. Owned by
  /// `ThemeProvider`, which restores it from prefs and writes to it;
  /// nothing else should assign to `.value`.
  static final ValueNotifier<AppIconPack> pack =
      ValueNotifier<AppIconPack>(AppIconPack.standard);

  /// Ticks once [warmUp] finishes, so icons already on screen can swap
  /// their Material fallback for the real artwork.
  ///
  /// The probe used to be awaited before `runApp`, which meant the
  /// first frame waited on ~70 asset round-trips — on the web those are
  /// HTTP requests, and on HTTP/1.1 they serialise six at a time, so
  /// the splash sat there for multiple RTTs' worth of icons that the
  /// user cannot even see yet. Now the app paints immediately with
  /// Material fallbacks (which [isDrawn] already returns before the
  /// probe runs) and the artwork arrives a beat later.
  ///
  /// A counter rather than a bool because [debugReset] can un-warm the
  /// cache between tests; listeners only care that *something* changed.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static bool get isWarm => _warm;

  /// True once [spec] has artwork in [pack] (defaults to the active one).
  static bool isDrawn(AppIconSpec spec, [AppIconPack? inPack]) =>
      _drawn.contains(_key(inPack ?? pack.value, spec));

  /// True when [spec]'s artwork in [pack] paints its own colours and
  /// must not be tinted — see [isMulticolorSource].
  static bool isMulticolor(AppIconSpec spec, [AppIconPack? inPack]) =>
      _multicolor.contains(_key(inPack ?? pack.value, spec));

  static String _key(AppIconPack pack, AppIconSpec spec) =>
      '${pack.id}/${spec.name}';

  /// Artwork is multicolour unless it defers its colour to the call
  /// site with `currentColor`.
  ///
  /// Sniffed from the file rather than declared on the spec so that
  /// redrawing an icon is a one-file change: swap a `currentColor`
  /// drawing for a painted one and the tint switches itself off at the
  /// next start-up. A file that mixes the two counts as tintable —
  /// `srcIn` would flatten the painted parts anyway, so honouring the
  /// call site's colour is the only reading that isn't half-broken.
  @visibleForTesting
  static bool isMulticolorSource(String svg) => !svg.contains('currentColor');

  /// Probes every spec's asset in every pack. An asset that is missing
  /// from the bundle, or present but empty (the placeholder state),
  /// counts as not drawn.
  ///
  /// Every pack is probed up front, not just the active one, so that
  /// switching packs later is a synchronous repaint with no async gap
  /// where icons would flicker back to their Material fallbacks.
  ///
  /// **Do not await this before `runApp`.** Start it and let the first
  /// frame go; [revision] fires when it lands and the icons swap
  /// themselves. Blocking on it costs real start-up time for artwork
  /// nobody can see yet: on the web `rootBundle.load` is an HTTP fetch,
  /// not a file read, and this issues one per spec per pack. Measured
  /// on a release build over localhost — no network latency at all —
  /// that was 71 requests spanning 295ms, all of it in front of the
  /// first frame. Over HTTP/1.1 the browser runs six at a time, so on a
  /// mobile connection the same set is ~12 sequential round-trips.
  ///
  /// The concurrency below still matters for the same reason: awaiting
  /// each probe in turn would serialise every one of them instead of
  /// overlapping them into roughly one round-trip. On mobile and
  /// desktop, where these are local reads, the shape costs little
  /// either way.
  static Future<void> warmUp({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    await Future.wait([
      for (final p in AppIconPack.values)
        for (final spec in AppIcons.all) _probe(b, p, spec),
    ]);
    _warm = true;
    revision.value++;
    if (kDebugMode) {
      for (final p in AppIconPack.values) {
        final n = AppIcons.all.where((s) => isDrawn(s, p)).length;
        debugPrint(
          'AppIcons[${p.id}]: $n/${AppIcons.all.length} custom icons '
          'drawn, the rest falling back to Material.',
        );
      }
    }
  }

  /// One spec's probe in one pack. Records the result in [_drawn] /
  /// [_multicolor] as a side effect; never throws, so a missing asset
  /// can't fail the whole [Future.wait].
  ///
  /// Mutating the sets from concurrent futures is safe: the awaits
  /// interleave on a single isolate, so no two probes are ever mid-write
  /// at the same time.
  static Future<void> _probe(
    AssetBundle b,
    AppIconPack p,
    AppIconSpec spec,
  ) async {
    try {
      final data = await b.load(spec.assetPathIn(p));
      if (data.lengthInBytes == 0) return;
      _drawn.add(_key(p, spec));
      final source = utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        allowMalformed: true,
      );
      if (isMulticolorSource(source)) {
        _multicolor.add(_key(p, spec));
      }
    } catch (_) {
      // Not in the bundle yet. Fallback stays in place; not worth a
      // log line, since an unfilled icon is the expected state while
      // the set is being drawn.
    }
  }

  /// Test hook — lets a test declare icons drawn without a real bundle.
  @visibleForTesting
  static void debugSetDrawn(
    Iterable<AppIconSpec> specs, {
    Iterable<AppIconSpec> multicolor = const [],
    AppIconPack inPack = AppIconPack.standard,
  }) {
    _drawn
      ..clear()
      ..addAll(specs.map((s) => _key(inPack, s)));
    _multicolor
      ..clear()
      ..addAll(multicolor.map((s) => _key(inPack, s)));
    _warm = true;
    revision.value++;
  }

  @visibleForTesting
  static void debugReset() {
    _drawn.clear();
    _multicolor.clear();
    pack.value = AppIconPack.standard;
    _warm = false;
    revision.value++;
  }
}
