import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

/// A bottom-anchored emoji picker that slides up under the chat
/// input bar. Curates ~70 emoji per category from the standard
/// Unicode set (smileys / people / animals / food / activities /
/// travel / objects / symbols) — enough variety for a family chat
/// without bloating the binary or overwhelming the UI.
///
/// Tapping an emoji calls [onEmojiSelected] with the character;
/// the chat room's TextEditingController is responsible for
/// cursor-aware insertion (see ChatRoomScreen._insertEmoji).
///
/// Categories are arranged as pages in a horizontal [PageView] —
/// the user can swipe left/right between them, or tap the bottom
/// tab bar to jump. `PageController` and the tab-bar's selected
/// index are kept in sync both ways via [_onPageChanged] /
/// [_select].
///
/// Why not a 3rd-party package? Two reasons:
///   1. The four leading Flutter emoji picker packages each add
///      ~300-500 KB and pull in dependencies we don't otherwise
///      need (cached_network_image, flutter_svg, etc.).
///   2. None of them support a fully-curated, family-friendly set
///      out of the box — they all default to the full Unicode list,
///      which includes skin-tone variants we don't need for v1.
class EmojiPicker extends StatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  final double height;

  const EmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.height = 280,
  });

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  late final PageController _pageController;
  int _categoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (_categoryIndex == i) return;
    setState(() => _categoryIndex = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    HapticFeedback.selectionClick();
  }

  void _onPageChanged(int i) {
    if (_categoryIndex == i) return;
    setState(() => _categoryIndex = i);
    HapticFeedback.selectionClick();
  }

  void _tap(String emoji) {
    widget.onEmojiSelected(emoji);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tooltips = <String>[
      l10n.emojiCategorySmileys,
      l10n.emojiCategoryPeople,
      l10n.emojiCategoryAnimals,
      l10n.emojiCategoryFood,
      l10n.emojiCategoryActivities,
      l10n.emojiCategoryTravel,
      l10n.emojiCategoryObjects,
      l10n.emojiCategorySymbols,
    ];
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemCount: _kCategories.length,
              itemBuilder: (ctx, i) =>
                  _EmojiGrid(emojis: _kCategories[i].emojis, onTap: _tap),
            ),
          ),
          _CategoryBar(
            currentIndex: _categoryIndex,
            tooltips: tooltips,
            onSelect: _select,
          ),
        ],
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  final List<String> emojis;
  final ValueChanged<String> onTap;
  const _EmojiGrid({required this.emojis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (ctx, i) {
        final e = emojis[i];
        return InkResponse(
          onTap: () => onTap(e),
          radius: 22,
          highlightShape: BoxShape.circle,
          child: Center(
            child: Text(e, style: const TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final int currentIndex;
  final List<String> tooltips;
  final ValueChanged<int> onSelect;
  const _CategoryBar({
    required this.currentIndex,
    required this.tooltips,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.linen,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < _kCategories.length; i++)
            _CategoryButton(
              icon: _kCategories[i].tab,
              tooltip: tooltips[i],
              selected: i == currentIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

/// One row in [kCategories]. The single character in [tab] doubles
/// as the visual identifier on the category bar and is the
/// first/most-recognizable emoji of the category.
class _EmojiCategory {
  final String tab;
  final List<String> emojis;
  const _EmojiCategory(this.tab, this.emojis);
}

/// Curated emoji set — 8 categories, ~60-80 each.
///
/// Sources: Unicode CLDR annotations for "en" (basic) plus the
/// iOS / WhatsApp / Telegram default-visible sets. Skin-tone
/// variants are deliberately omitted for v1 — keep the picker
/// small and the data file readable in version control.
///
/// Adding new emoji? Just append to the right list — the grid
/// re-flows automatically.
const List<_EmojiCategory> _kCategories = [
  // ── Smileys & Emotion ──────────────────────────────────────────
  _EmojiCategory('😀', [
    '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃',
    '😉','😊','😇','🥰','😍','🤩','😘','😗','☺️','😚',
    '😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭',
    '🤫','🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄',
    '😬','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕',
    '🤧','🥵','🥶','🥴','😵','🤯','🤠','🥳','😎','🤓',
    '🧐','😕','😟','🙁','☹️','😮','😯','😲','😳','🥺',
    '😦','😧','😨','😰','😥','😢','😭','😱','😖','😣',
    '😞','😓','😩','😫','🥱','😤','😡','😠','🤬','😈',
    '👿','💀','☠️','💩','🤡','👹','👺','👻','👽','👾',
    '🤖','😺','😸','😹','😻','😼','😽','🙀','😿','😾',
  ]),
  // ── People & Body ──────────────────────────────────────────────
  _EmojiCategory('👋', [
    '👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞',
    '🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍',
    '👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝',
    '🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂',
    '🦻','👃','🧠','🦷','🦴','👀','👁️','👅','👄','💋',
    '🩸','👶','🧒','👦','👧','🧑','👱','👨','🧔','👩',
    '🧓','👴','👵','🙅','🙆','💁','🙋','🧏','🙇','🤦',
    '🤷','👮','🕵️','💂','👷','🤴','👸','👳','👲','🧕',
    '🤵','👰','🤰','🤱','👼','🎅','🤶','🦸','🦹','🧙',
    '🧚','🧛','🧜','🧝','🧞','🧟','💆','💇','🚶','🧎',
    '🏃','💃','🕺','🧎‍','🧑‍','👫','👬','👭','💏','💑',
  ]),
  // ── Animals & Nature ───────────────────────────────────────────
  _EmojiCategory('🐶', [
    '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯',
    '🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊','🐒',
    '🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦅','🦉','🦇',
    '🐺','🐗','🐴','🦄','🐝','🐛','🦋','🐌','🐞','🐜',
    '🪲','🪳','🦟','🦗','🕷️','🕸️','🦂','🐢','🐍','🦎',
    '🐙','🦑','🦐','🦞','🦀','🐡','🐠','🐟','🐬','🐳',
    '🐋','🦈','🐊','🐅','🐆','🦓','🦍','🦧','🐘','🦛',
    '🦏','🐪','🐫','🦒','🦘','🐃','🐂','🐄','🐎','🐖',
    '🐏','🐑','🦙','🐐','🦌','🐕','🐩','🦮','🐈','🐓',
    '🦃','🦚','🦜','🦢','🦩','🕊️','🐇','🦝','🦨','🦡',
    '🦦','🦥','🐁','🐀','🐿️','🦔','🌲','🌳','🌴','🌵',
    '🌾','🌿','☘️','🍀','🍁','🍂','🍃','🌺','🌻','🌹',
  ]),
  // ── Food & Drink ───────────────────────────────────────────────
  _EmojiCategory('🍎', [
    '🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐',
    '🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🍆','🥑',
    '🥦','🥬','🥒','🌶️','🫑','🌽','🥕','🫒','🧄','🧅',
    '🥔','🍠','🥐','🥯','🍞','🥖','🥨','🧀','🥚','🍳',
    '🧈','🥞','🧇','🥓','🥩','🍗','🍖','🦴','🌭','🍔',
    '🍟','🍕','🥪','🥙','🧆','🌮','🌯','🫔','🥗','🥘',
    '🫕','🥫','🍝','🍜','🍲','🍛','🍣','🍱','🥟','🦪',
    '🍤','🍙','🍚','🍘','🍥','🥠','🥮','🍢','🍡','🍧',
    '🍨','🍦','🥧','🧁','🍰','🎂','🍮','🍭','🍬','🍫',
    '🍿','🍩','🍪','🌰','🥜','🫘','🍯','🥛','🍼','☕',
    '🍵','🧃','🥤','🧋','🍶','🍺','🍻','🥂','🍷','🥃',
  ]),
  // ── Activities & Sports ────────────────────────────────────────
  _EmojiCategory('⚽', [
    '⚽','⚾','🥎','🏀','🏐','🏈','🏉','🥏','🎱','🪀',
    '🏓','🏸','🏒','🏑','🥍','🏏','⛳','🪁','🏹','🎣',
    '🤿','🥊','🥋','🎽','🛹','🛼','🛷','⛸️','🥌','🎿',
    '⛷️','🏂','🪂','🏋️','🤼','🤸','⛹️','🤺','🤾','🏌️',
    '🏇','🧘','🏄','🏊','🤽','🚣','🧗','🚵','🚴','🏆',
    '🥇','🥈','🥉','🏅','🎖️','🏵️','🎗️','🎫','🎟️','🎪',
    '🤹','🎭','🩰','🎨','🎬','🎤','🎧','🎼','🎹','🥁',
    '🪘','🎷','🎺','🎸','🪕','🎻','🎲','♟️','🎯','🎳',
    '🎮','🎰','🧩','🪅','🪆','🎴','🎁','🎀','🎈','🎏',
  ]),
  // ── Travel & Places ────────────────────────────────────────────
  _EmojiCategory('🚗', [
    '🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐',
    '🛻','🚚','🚛','🚜','🦯','🦽','🦼','🛴','🚲','🛵',
    '🏍️','🛺','🚨','🚔','🚍','🚘','🚖','🚡','🚠','🚟',
    '🚃','🚋','🚞','🚝','🚄','🚅','🚈','🚂','🚆','🚇',
    '🚊','🚉','✈️','🛫','🛬','🛩️','💺','🛰️','🚀','🛸',
    '🚁','🛶','⛵','🚤','🛥️','🛳️','⛴️','🚢','⚓','🚧',
    '⛽','🚏','🚦','🚥','🛑','🗺️','🗿','🗽','🗼','🏰',
    '🏯','🏟️','🎡','🎢','🎠','⛲','⛱️','🏖️','🏝️','🏜️',
    '🌋','⛰️','🏔️','🗻','🏕️','⛺','🏠','🏡','🏘️','🏚️',
    '🏗️','🏭','🏢','🏬','🏣','🏤','🏥','🏦','🏨','🏪',
    '🏫','🏩','💒','🏛️','⛪','🕌','🕍','🛕','🕋','⛩️',
    '🌅','🌄','🌠','🎇','🎆','🌇','🌆','🏙️','🌃','🌌',
  ]),
  // ── Objects ────────────────────────────────────────────────────
  _EmojiCategory('💡', [
    '💡','🔦','🕯️','🪔','🧯','🛢️','💸','💵','💴','💶',
    '💷','🪙','💰','💳','💎','⚖️','🪜','🧰','🪛','🔧',
    '🔨','⚒️','🛠️','⛏️','🪚','🔩','⚙️','🪤','🧱','⛓️',
    '🧲','🔫','💣','🧨','🪓','🔪','🗡️','⚔️','🛡️','🚬',
    '⚰️','🪦','⚱️','🏺','🔮','📿','🧿','💈','⚗️','🔭',
    '🔬','🕳️','🩹','🩺','💊','💉','🦠','🧬','🧫','🛁',
    '🛀','🧴','🧷','🧹','🧺','🧻','🚽','🚰','🚿','🧼',
    '🪒','🧽','🪣','🧸','🪆','🖼️','🎨','🧵','🪡','🧶',
    '🪢','👑','👒','🎩','🧢','⛑️','💄','💍','🎒','🧳',
    '👞','👟','🥾','🥿','👠','👡','🩰','👢','🪮','🧣',
    '🧤','🧥','🥼','🦺','👔','👕','👖','🩳','🩲','🩱',
    '👘','🥻','📱','📲','☎️','📞','📟','📠','🔋','🔌',
  ]),
  // ── Symbols ────────────────────────────────────────────────────
  _EmojiCategory('❤️', [
    '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔',
    '❣️','💕','💞','💓','💗','💖','💘','💝','💟','☮️',
    '✝️','☪️','🕉️','☸️','✡️','🔯','🕎','🔮','⚛️','☯️',
    '☦️','🛐','⛎','♈','♉','♊','♋','♌','♍','♎',
    '♏','♐','♑','♒','♓','🆔','⚜️','🔱','📛','🔰',
    '⭕','✅','❌','❎','❓','❔','‼️','⁉️','🔅','🔆',
    '〽️','⚠️','🚸','🔱','🔻','🔺','🔹','🔸','🔲','🔳',
    '🟥','🟧','🟨','🟩','🟦','🟪','🟫','⬛','⬜','🟫',
    '🟢','🔴','🔵','⚫','⚪','🟣','🟡','🟠','💯','💢',
    '💥','💫','💦','💨','🕳️','💣','💬','👁️‍🗨️','🗨️','🗯️',
    '💭','💤','🌟','⭐','🌠','☀️','🌤️','⛅','🌥️','🌦️',
    '🌧️','⛈️','🌩️','🌨️','❄️','☃️','⛄','🌬️','💨','💧',
  ]),
];