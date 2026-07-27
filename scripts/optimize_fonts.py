#!/usr/bin/env python3
"""Shrink the bundled fonts in assets/fonts/.

Two independent problems, two fixes:

1. NotoEmoji-Regular.ttf is the COLOUR build, and it ships the same
   1499 emoji twice over: as COLRv1 layers and again as an `SVG `
   table. Skia renders COLRv1 and ignores `SVG `, so that table is
   19MB nothing ever reads. Dropped.

   `COLR`/`CPAL` must NOT be dropped with it. Every emoji's base glyph
   in this font has an EMPTY `glyf` outline — the artwork lives purely
   in the colour layers — so a font stripped down to `glyf` maps every
   emoji to a blank, and they all silently vanish.

2. The CJK fonts carry every codepoint their script defines — 30890
   for Simplified Chinese. Exported chats are ordinary prose, so the
   national standard character sets (GB2312, Big5, JIS X 0208,
   KS X 1001) cover them with room to spare at a fraction of the size.

Both outputs are written next to the originals with a `.min.ttf`
suffix; nothing is overwritten in place, so a bad subset is a `git
checkout` away from being reverted.

Usage:  python scripts/optimize_fonts.py
"""

from __future__ import annotations

import os
import sys

from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter, Options

FONT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "fonts")

# The redundant colour rendering. `COLR`/`CPAL` stay — see the module
# docstring for what happens if they don't.
REDUNDANT_TABLES = ["SVG "]


def codepoints_from_codec(codec: str) -> set[int]:
    """Every character a legacy CJK encoding can represent.

    Round-trips the whole two-byte space through the codec and keeps
    what survives — cheaper than shipping a hardcoded 7000-line list,
    and guaranteed to match what the standard actually defines.
    """
    found: set[int] = set()
    for hi in range(0x81, 0xFF):
        for lo in range(0x40, 0xFF):
            try:
                ch = bytes([hi, lo]).decode(codec)
            except (UnicodeDecodeError, ValueError):
                continue
            if len(ch) == 1:
                found.add(ord(ch))
    return found


def always_keep() -> set[int]:
    """ASCII, Latin-1 and the CJK punctuation every script shares."""
    keep = set(range(0x20, 0x7F)) | set(range(0xA0, 0x100))
    keep |= set(range(0x2000, 0x206F))   # general punctuation
    keep |= set(range(0x3000, 0x3040))   # CJK punctuation + kana marks
    keep |= set(range(0xFF00, 0xFFF0))   # fullwidth forms
    keep |= {0xFFFD}                     # replacement char
    return keep


def subset(src: str, dst: str, keep: set[int], drop_tables: list[str] | None = None) -> None:
    font = TTFont(src)

    if drop_tables:
        for tag in drop_tables:
            if tag in font:
                del font[tag]

    if keep:
        options = Options()
        # Layout features are what make the difference between text that
        # merely renders and text that renders correctly — kerning,
        # vertical forms, and the Korean/Japanese composition rules.
        options.layout_features = ["*"]
        options.drop_tables = []
        options.notdef_outline = True
        options.recalc_bounds = True
        subsetter = Subsetter(options=options)
        subsetter.populate(unicodes=keep)
        subsetter.subset(font)

    font.save(dst)


def main() -> int:
    if not os.path.isdir(FONT_DIR):
        print(f"font dir not found: {FONT_DIR}", file=sys.stderr)
        return 1

    shared = always_keep()

    # (file, codepoints to keep, tables to drop)
    jobs = [
        # Emoji: keep every glyph and its colour layers, lose only the
        # duplicate `SVG ` rendering.
        ("NotoEmoji-Regular.ttf", None, REDUNDANT_TABLES),
        ("NotoSansSC-Regular.ttf", codepoints_from_codec("gb2312") | shared, None),
        ("NotoSansTC-Medium.ttf", codepoints_from_codec("big5") | shared, None),
        ("NotoSansJP-Regular.ttf", codepoints_from_codec("shift_jis") | shared, None),
        ("NotoSansKR-Regular.ttf", codepoints_from_codec("euc_kr") | shared, None),
        # Myanmar is already 0.2MB — not worth the risk of trimming.
    ]

    total_before = total_after = 0
    for name, keep, drop in jobs:
        src = os.path.join(FONT_DIR, name)
        if not os.path.exists(src):
            print(f"  skip (missing): {name}")
            continue
        dst = os.path.join(FONT_DIR, name.replace(".ttf", ".min.ttf"))
        before = os.path.getsize(src)
        subset(src, dst, keep or set(), drop)
        after = os.path.getsize(dst)
        total_before += before
        total_after += after
        print(
            f"  {name:32} {before/1048576:6.1f}MB -> {after/1048576:5.1f}MB "
            f"({100 - after*100//before:2d}% smaller)"
        )

    print(
        f"\n  total {total_before/1048576:.1f}MB -> {total_after/1048576:.1f}MB "
        f"(saved {(total_before-total_after)/1048576:.1f}MB)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
