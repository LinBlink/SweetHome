#!/usr/bin/env python3
"""Build the bundled UI font set.

Why this exists: CanvasKit has no access to system fonts. Any codepoint
it can't find in a registered font it downloads from
`https://fonts.gstatic.com/s/` at runtime — which is both an extra
round trip on first paint and, for users behind the GFW, unreachable,
so Chinese text renders as tofu boxes.

The fix is to bundle enough coverage that the fallback never fires for
ordinary use. "Enough" is defined here as:

  * every character that appears in any `lib/l10n/*.arb` file, so the
    app's own chrome always renders in all seven supported locales; plus
  * GB2312 level 1 (the 3755 most common hanzi), so everyday
    user-typed Simplified Chinese renders too.

Anything rarer — obscure hanzi, Japanese/Korean *content* (as opposed
to UI labels), emoji — still falls back to the network. Point
`fontFallbackBaseUrl` at a self-hosted mirror so that path works from
mainland China as well; see web/index.html.

Each script gets its own file rather than one merged font because
merging TrueType outlines across families is fragile, and Flutter's
`fontFamilyFallback` chains them just as well at no extra cost.

Usage:  python scripts/build_ui_fonts.py
"""

from __future__ import annotations

import glob
import json
import os
import sys

from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter, Options

ROOT = os.path.join(os.path.dirname(__file__), "..")
FONT_DIR = os.path.join(ROOT, "assets", "fonts")
UI_DIR = os.path.join(FONT_DIR, "ui")
L10N_DIR = os.path.join(ROOT, "lib", "l10n")


def shared_codepoints() -> set[int]:
    """ASCII, Latin-1 and the punctuation every script shares."""
    keep = set(range(0x20, 0x7F)) | set(range(0xA0, 0x100))
    keep |= set(range(0x2000, 0x206F))   # general punctuation
    keep |= set(range(0x3000, 0x3040))   # CJK punctuation
    keep |= set(range(0xFF00, 0xFFF0))   # fullwidth forms
    keep |= {0xFFFD}
    return keep


def gb2312_level1() -> set[int]:
    """The 3755 most common hanzi — GB2312's first tier, ordered by use."""
    out: set[int] = set()
    for hi in range(0xB0, 0xD8):
        for lo in range(0xA1, 0xFF):
            try:
                ch = bytes([hi, lo]).decode("gb2312")
            except (UnicodeDecodeError, ValueError):
                continue
            if len(ch) == 1:
                out.add(ord(ch))
    return out


def arb_codepoints(*basenames: str) -> set[int]:
    """Every character used in the given ARB files' message values."""
    out: set[int] = set()
    for base in basenames:
        path = os.path.join(L10N_DIR, base)
        if not os.path.exists(path):
            print(f"  warn: missing {base}")
            continue
        data = json.load(open(path, encoding="utf8"))
        for key, value in data.items():
            # Keys starting with @ are metadata, not displayed text.
            if not key.startswith("@") and isinstance(value, str):
                out.update(ord(c) for c in value)
    return out


def dart_source_codepoints() -> set[int]:
    """CJK characters hardcoded in Dart rather than routed through l10n.

    `test/no_hardcoded_cjk_test.dart` exists to stop these appearing,
    but a few slip through (the theme names in profile_screen.dart, for
    one) and a character that's on screen still needs a glyph whether
    or not it should have been in an ARB file. Scanning the whole file
    rather than just string literals also picks up Chinese comments —
    harmless, since a handful of extra glyphs costs almost nothing.
    """
    out: set[int] = set()
    for path in glob.glob(os.path.join(ROOT, "lib", "**", "*.dart"), recursive=True):
        for ch in open(path, encoding="utf8", errors="ignore").read():
            # From CJK radicals up; skips Latin/punctuation already covered.
            if ord(ch) >= 0x2E80:
                out.add(ord(ch))
    return out


def build(src_name: str, out_name: str, keep: set[int]) -> tuple[int, list[str]]:
    src = os.path.join(FONT_DIR, src_name)
    font = TTFont(src)
    available = set(font.getBestCmap())
    missing = sorted(keep - available - set(range(0x00, 0x20)))

    options = Options()
    options.layout_features = ["*"]
    options.drop_tables = []
    options.notdef_outline = True
    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=keep & available)
    subsetter.subset(font)

    os.makedirs(UI_DIR, exist_ok=True)
    dst = os.path.join(UI_DIR, out_name)
    font.save(dst)
    return os.path.getsize(dst), [chr(c) for c in missing]


def main() -> int:
    shared = shared_codepoints()
    # Offered to every subset, not just the Simplified one: the literals
    # hardcoded in Dart are a mix of scripts, and `build` intersects the
    # request with what each source font actually has, so a character
    # simply lands in whichever subset can render it.
    hardcoded = dart_source_codepoints()

    jobs = [
        # (source font, output, codepoints)
        ("NotoSansSC-Regular.ttf", "ui_sc.ttf",
         gb2312_level1() | arb_codepoints("app_zh.arb", "app_zh_Hans.arb", "app_en.arb")
         | hardcoded | shared),
        ("NotoSansTC-Medium.ttf", "ui_tc.ttf",
         arb_codepoints("app_zh_Hant.arb") | hardcoded | shared),
        ("NotoSansJP-Regular.ttf", "ui_jp.ttf",
         arb_codepoints("app_ja.arb") | set(range(0x3040, 0x3100)) | hardcoded | shared),
        ("NotoSansKR-Regular.ttf", "ui_kr.ttf",
         arb_codepoints("app_ko.arb") | hardcoded | shared),
        ("NotoSansMyanmar-Regular.ttf", "ui_my.ttf",
         arb_codepoints("app_my.arb") | hardcoded | shared),
        # Emoji last, so it only ever supplies what no text font has.
        #
        # Every codepoint the font defines, not just the ~900 the emoji
        # picker hardcodes, because received messages can contain any of
        # them. Narrowing it to the picker's set saves barely 0.3MB.
        #
        # This is the COLOUR build (COLRv1 layers). Do not be tempted to
        # strip `COLR`/`CPAL` to save space: the base glyphs here have
        # empty `glyf` outlines, so a colour-stripped font maps every
        # emoji to a blank and they all disappear.
        #
        # Bundling it is the only option — the engine's usual source for
        # emoji, fonts.gstatic.com, is reachable by neither the client
        # nor the server.
        ("NotoEmoji-Regular.ttf", "ui_emoji.ttf", None),
    ]

    total = 0
    # Each font only needs to carry what the ones ahead of it in the
    # fallback chain don't already have. Without this the Han ideographs
    # hardcoded in Dart get duplicated into the TC, JP and KR subsets —
    # those fonts cover Han too — for about 700KB of dead weight.
    already: set[int] = set()
    for src, out, keep in jobs:
        if not os.path.exists(os.path.join(FONT_DIR, src)):
            print(f"  skip (missing source): {src}")
            continue
        # `None` means "whatever this font defines" — used by the emoji
        # font, where the useful set is the font's own repertoire.
        if keep is None:
            keep = set(TTFont(os.path.join(FONT_DIR, src), lazy=True).getBestCmap())
            keep |= {0xFE0F, 0x200D}   # variation selector + ZWJ
        size, _ = build(src, out, keep - already)
        total += size
        already |= set(TTFont(os.path.join(UI_DIR, out), lazy=True).getBestCmap())
        print(f"  {out:12} {size/1024:7.0f} KB   from {src}")

    print(f"\n  UI font set total: {total/1048576:.2f} MB")

    # What matters is coverage of the *set*, not of any one file: a
    # character missing from ui_tc is fine as long as ui_sc has it,
    # because fontFamilyFallback chains them. So the only real gap is
    # what no bundled font covers.
    covered: set[int] = set()
    for name in sorted(os.listdir(UI_DIR)):
        if name.endswith(".ttf"):
            covered |= set(TTFont(os.path.join(UI_DIR, name), lazy=True).getBestCmap())

    needed = arb_codepoints(*(os.path.basename(p) for p in glob.glob(os.path.join(L10N_DIR, "*.arb"))))
    needed |= dart_source_codepoints()
    gap = sorted(c for c in needed - covered if c >= 0x20)
    if gap:
        print(
            f"  UI text needing the network fallback ({len(gap)}): "
            f"{''.join(chr(c) for c in gap)}"
        )
    else:
        print("  Every character in every ARB file is covered offline.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
