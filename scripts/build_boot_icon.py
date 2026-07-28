#!/usr/bin/env python3
"""Embed the app icon into web/index.html's boot splash.

Why the icon is inlined rather than linked: the boot splash is the
first thing painted, before Flutter — before `main.dart.js` has even
been requested. A linked `<img>` can't be fetched until the HTML has
parsed, so for a beat the splash has a hole where its logo should be,
which is exactly the "nothing on screen" state the splash exists to
prevent. A data URI is on screen with the markup.

Why a script rather than a pasted blob: base64 in a source file is
unreviewable and drifts silently from the artwork. Run this after
changing `assets/icons/app_icon.png` and the two stay in step.

The icon is resampled to 192px for a 96px box — 2x for high-DPI
screens, and about 6.5KB of base64, which is cheap enough to sit in
the critical HTML.

Usage:  python scripts/build_boot_icon.py
        python scripts/build_boot_icon.py --check   (CI: verify in sync)
"""

from __future__ import annotations

import argparse
import base64
import io
import os
import re
import sys

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
SOURCE = os.path.join(ROOT, "assets", "icons", "app_icon.png")
INDEX = os.path.join(ROOT, "web", "index.html")

RENDER_PX = 192   # 2x the 96px CSS box

# Matches either the placeholder or a previously generated data URI, so
# the script is idempotent and can be re-run over its own output.
SRC_PATTERN = re.compile(
    r'(<img src=")(?:__BOOT_ICON_DATA_URI__|data:image/png;base64,[A-Za-z0-9+/=]*)(")'
)


def build_data_uri() -> str:
    icon = Image.open(SOURCE).convert("RGB")
    icon = icon.resize((RENDER_PX, RENDER_PX), Image.LANCZOS)
    buf = io.BytesIO()
    icon.save(buf, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="exit non-zero if index.html is out of date")
    args = parser.parse_args()

    data_uri = build_data_uri()

    with io.open(INDEX, encoding="utf-8") as f:
        html = f.read()

    if not SRC_PATTERN.search(html):
        print("error: no boot icon <img> found in web/index.html — has the "
              "splash markup changed?", file=sys.stderr)
        return 2

    updated = SRC_PATTERN.sub(lambda m: m.group(1) + data_uri + m.group(2), html)

    if args.check:
        if updated != html:
            print("error: web/index.html's boot icon is out of date with "
                  "assets/icons/app_icon.png — run "
                  "`python scripts/build_boot_icon.py`", file=sys.stderr)
            return 1
        print("boot icon is in sync")
        return 0

    if updated == html:
        print("boot icon already up to date")
        return 0

    with io.open(INDEX, "w", encoding="utf-8", newline="") as f:
        f.write(updated)
    print("embedded %s at %dpx (%.1f KB of base64) into web/index.html"
          % (os.path.relpath(SOURCE, ROOT), RENDER_PX, len(data_uri) / 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
