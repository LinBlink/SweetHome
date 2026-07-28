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
to UI labels), colour emoji — still falls back to the network, which is
fine: `scripts/fetch_gfonts_mirror.py` puts the engine's whole fallback
set on our own origin, so that path works from mainland China and, more
importantly, *succeeds*. It has to. The engine never records a failed
fallback download, so a 404 there is not one 404 but an endless retry
loop. See docs/web-deploy.md.

This subset is therefore an optimisation, not a correctness
requirement: it keeps the app's own chrome and everyday Chinese off the
network entirely, instead of paying a round trip per script on first
paint.

Each script gets its own file rather than one merged font because
merging TrueType outlines across families is fragile, and Flutter's
`fontFamilyFallback` chains them just as well at no extra cost.

Usage:  python scripts/build_ui_fonts.py
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
import unicodedata

from fontTools.ttLib import TTFont
from fontTools.subset import Subsetter, Options

ROOT = os.path.join(os.path.dirname(__file__), "..")
FONT_DIR = os.path.join(ROOT, "assets", "fonts")
UI_DIR = os.path.join(FONT_DIR, "ui")
L10N_DIR = os.path.join(ROOT, "lib", "l10n")


def shared_codepoints() -> set[int]:
    """ASCII, Latin-1, shared punctuation, and the symbol blocks.

    The symbol blocks are requested wholesale rather than harvested from
    the app's text, because the text scan cannot see them coming. A "≥"
    in an error message, a "→" in a label, a "①" in a list, an arrow
    that arrives inside a chat message someone typed on another device —
    none of that is in an ARB file at build time, and every one of them
    is a tofu box plus a doomed font fetch on every layout that contains
    it. `build` intersects each request with what the source font
    actually has, so asking for whole blocks costs only the glyphs that
    exist: ~618 across all of them, tens of KB.

    This is the same failure the Burmese digits had, generalised: a
    codepoint that is generated or received at runtime rather than
    written into a translation file.
    """
    keep = set(range(0x20, 0x7F)) | set(range(0xA0, 0x100))
    keep |= set(range(0x2000, 0x206F))   # general punctuation
    keep |= set(range(0x3000, 0x3040))   # CJK punctuation
    keep |= set(range(0xFF00, 0xFFF0))   # fullwidth forms
    keep |= {0xFFFD}

    # Anything CanvasKit would otherwise go to Noto Sans Symbols /
    # Symbols 2 / Math for.
    keep |= set(range(0x2190, 0x2200))   # arrows
    keep |= set(range(0x2200, 0x2300))   # mathematical operators
    keep |= set(range(0x2300, 0x2400))   # miscellaneous technical
    keep |= set(range(0x2460, 0x2500))   # enclosed alphanumerics
    keep |= set(range(0x2500, 0x25A0))   # box drawing + block elements
    keep |= set(range(0x25A0, 0x2600))   # geometric shapes
    keep |= set(range(0x2600, 0x2700))   # miscellaneous symbols
    keep |= set(range(0x2700, 0x27C0))   # dingbats
    keep |= set(range(0x2900, 0x2980))   # supplemental arrows-B
    keep |= set(range(0x3200, 0x3400))   # enclosed CJK + CJK compatibility
    return keep


def myanmar_digits() -> set[int]:
    """Burmese digits U+1040-1049.

    These have to be requested explicitly because the ARB scan cannot
    see them: `intl` renders numbers into Burmese digits at *runtime*
    for the `my` locale, so a digit only survives subsetting if it also
    happens to appear literally in some translated string. That is what
    had happened — 0/2/4/6/8 were in the ARB text somewhere and lived,
    1/3/5/7/9 were not and were dropped, so every odd digit in the
    Burmese UI rendered as tofu and sent the engine off to the font
    fallback for each one.

    Nothing equivalent is needed for the other locales: zh/ja/ko/en all
    format numbers with ASCII digits, which `shared_codepoints` covers.
    """
    return set(range(0x1040, 0x104A))


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


_BLOCK_COMMENT_RE = re.compile(r"/\*(?:.|\n)*?\*/")
_LINE_COMMENT_RE = re.compile(r"//.*$", re.MULTILINE)
_LITERAL_RE = re.compile(
    r"'''(?:.|\n)*?'''"          # triple-single
    r'|"""(?:.|\n)*?"""'         # triple-double
    r"|'(?:\\.|[^'\\\n])*'"      # single
    r'|"(?:\\.|[^"\\\n])*"'      # double
)


def dart_string_literal_codepoints() -> set[int]:
    """Characters inside Dart string literals, comments excluded.

    Used only by --check, and deliberately different from
    [dart_source_codepoints]: that one floors at 0x2E80, so it cannot
    see a "≥" or a "→" at all — those sit below the floor and above the
    punctuation range `shared_codepoints` used to stop at. For a long
    time nothing here could tell you such a character was uncovered, so
    the check passed while the app rendered a tofu box and hit the
    network on every layout containing it.

    Comments are stripped: a symbol in a doc comment is never laid out
    and must not fail the build.
    """
    out: set[int] = set()
    for path in glob.glob(os.path.join(ROOT, "lib", "**", "*.dart"), recursive=True):
        src = open(path, encoding="utf8", errors="ignore").read()
        src = _BLOCK_COMMENT_RE.sub("", src)
        src = _LINE_COMMENT_RE.sub("", src)
        for match in _LITERAL_RE.finditer(src):
            out.update(ord(c) for c in match.group(0))
    return out


def mirror_emoji_codepoints() -> set[int]:
    """Codepoints deliberately left to the fallback mirror.

    Emoji used to be bundled and are not any more — `/gfonts/` serves
    the complete Noto Color Emoji, which is both smaller at first paint
    and better than any subset we could build (see the `jobs` list). So
    an emoji in `emoji_picker.dart` is not a coverage hole and must not
    fail --check.

    Read out of the emoji font's own cmap rather than hardcoded as
    ranges. A range guess gets this wrong in a way that is easy to miss:
    ✅ ❌ ❔ ✊ sit down in Dingbats, inside the block
    `shared_codepoints()` already asks for, and Noto Sans Symbols — the
    font that request lands in — has no glyphs for them. Only the emoji
    font does. "Which characters does the mirror's emoji font cover" is
    the actual question, so ask it.

    `assets/fonts/NotoEmoji-Regular.ttf` is the same upstream font the
    mirror serves as `notocoloremoji`; it stays in the bundle for PDF
    export (see ChatExportPdfService).
    """
    path = os.path.join(FONT_DIR, "NotoEmoji-Regular.ttf")
    if not os.path.exists(path):
        print(f"  warn: {os.path.basename(path)} missing — emoji will be "
              f"reported as coverage gaps")
        return set()
    return set(TTFont(path, lazy=True).getBestCmap())


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
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="exit non-zero if any UI text has no bundled glyph")
    args = parser.parse_args()

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
         arb_codepoints("app_my.arb") | myanmar_digits() | hardcoded | shared),
        # Noto Sans Symbols / Symbols 2 — bundled at FULL cmap (not
        # subsetted to `shared_codepoints()`), because the Flutter Web
        # engine's `FontFallbackManager` has a hardcoded map
        # (`codePointToComponents` in font_fallback_data.dart) that
        # routes codepoints to "Noto Sans Symbols" v43 by name. That
        # map covers far more than the symbol blocks — Latin
        # Extended-A/B, Spacing Modifier Letters, IPA, etc. — and any
        # codepoint the engine's map attributes to "Noto Sans Symbols"
        # that our chain doesn't cover triggers a fetch to
        # `fontFallbackBaseUrl`. On dev that's a 404; a failed
        # download is NOT cached, so the engine re-queues the same
        # font on every relayout — a permanent 404 loop at
        # `notifyListeners` frequency. Keeping the full source cmap
        # (minus overlaps with the CJK/MY fonts ahead of them in the
        # chain) plugs every hole the engine knows about. `None` =
        # "whatever the source font defines".
        ("NotoSansSymbols-Regular.ttf", "ui_symbols.ttf", None),
        ("NotoSansSymbols2-Regular.ttf", "ui_symbols2.ttf", None),
        # No emoji job. There used to be one — the whole of Noto Color
        # Emoji, 3.8MB, bundled because fonts.gstatic.com was reachable
        # by neither the client nor the server. `fetch_gfonts_mirror.py`
        # removed that constraint: the engine's own emoji font now comes
        # from our origin, in full, on demand.
        #
        # Which is strictly better, because subsetting a COLR font was
        # never clean. It dropped U+200D and ~9500 glyphs, and with the
        # ZWJ gone the shaper could not form family sequences or flags —
        # 3.8MB on every first paint, for coverage worse than the
        # original. Do not add it back.
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
    needed |= dart_string_literal_codepoints()
    gap = sorted(c for c in needed - covered if c >= 0x20)

    # Invisible formatting characters. No font has a glyph for them and
    # none is needed — the shaper consumes them — so they are not a
    # coverage hole and must not fail the check.
    FORMAT_ONLY = {0xFE0F, 0x200D, 0xFEFF}
    from_mirror = mirror_emoji_codepoints()
    real_gap = [c for c in gap
                if c not in FORMAT_ONLY and c not in from_mirror]

    # Emoji are expected here and there are hundreds of them, so they get
    # a count; anything else gets printed, because anything else is a
    # surprise worth reading.
    emoji_gap = [c for c in gap if c in from_mirror]
    other_gap = [c for c in gap if c not in from_mirror
                 and c not in FORMAT_ONLY]
    if emoji_gap:
        print(f"  emoji served from the /gfonts/ mirror: {len(emoji_gap)}")
    if other_gap:
        print(
            f"  UI text needing the network fallback ({len(other_gap)}): "
            f"{''.join(chr(c) for c in other_gap)}"
        )
    else:
        print("  Every non-emoji character in the UI is covered offline.")

    if real_gap:
        # Loud, and fatal under --check. Not because an uncovered
        # codepoint is unrenderable — the fallback mirror answers now,
        # so it will render — but because it costs a network round trip
        # and a full re-layout, and for text this static (our own
        # labels, everyday hanzi) that is pure waste. Mojibake shows up
        # here too: a stray U+FFFD from a bad encoding round-trip is
        # worth failing a build over.
        print()
        for c in real_gap:
            try:
                name = unicodedata.name(chr(c))
            except ValueError:
                name = "<unnamed>"
            print(f"  !! U+{c:04X} {chr(c)!r} {name} — costs a fallback "
                  f"download and a re-layout on first paint")
        print()
        print("  If this is mojibake, fix the source string. If it is a "
              "real character, add it to the subset request above.")

    if args.check:
        return 1 if real_gap else 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
