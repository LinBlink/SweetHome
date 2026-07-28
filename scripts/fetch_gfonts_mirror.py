#!/usr/bin/env python3
"""Mirror the Flutter Web engine's fallback fonts into `web/gfonts/`.

## Why

CanvasKit cannot see system fonts. Any codepoint it can't find in a
registered family it fetches from `fontFallbackBaseUrl` at layout time.
We bundle a subset (see `build_ui_fonts.py`) that covers the app's own
chrome plus the 3755 most common hanzi, and for a long time the plan
for everything else was to fail fast: nginx answered 404 under
`/gfonts/` on purpose, on the theory that a missing glyph should
degrade to tofu rather than hang.

That theory is wrong, and the engine is why. `_FallbackFontDownloadQueue`
does not remember a *failed* download — on error it drops the URL from
`pendingFonts` and never adds it to `downloadedFonts`. Draining a batch
then broadcasts a font-change message, which re-lays out every paragraph
in the app, which re-discovers the same missing codepoint, which queues
the same font again. One uncovered character is therefore not one 404;
it is an unbounded loop of them, at frame rate if the text sits in an
animated build.

And the set of uncovered characters is not something we can close by
subsetting harder, because it isn't ours: a name, a chat message or an
address arriving from the server can contain any hanzi, any script, any
emoji. `build_ui_fonts.py` scans `lib/l10n/*.arb` and `lib/**/*.dart` —
it cannot see what a user will type.

So the fallback has to actually work. The whole set is 724 files and
~21 MB, and a client only ever downloads the handful of ~25 KB chunks
its text needs, so mirroring all of it costs disk on the server and
nothing on first paint. That buys unlimited coverage — every script the
engine knows about, plus colour emoji — and it ends the loop for good,
because a download that succeeds is one the engine remembers.

## Why parse the SDK instead of hardcoding a list

`font_fallback_data.dart` ships inside the Flutter SDK and its URLs
carry Google Fonts version tokens (`notosanssc/v37/...`). Upgrading
Flutter can bump them, and the engine will then ask for URLs no mirror
built against the old SDK has. Reading the list out of the SDK that is
actually going to compile the app keeps the two in lockstep: after a
Flutter upgrade, re-run this script and the new files appear.

## Usage

    python scripts/fetch_gfonts_mirror.py           # download what's missing
    python scripts/fetch_gfonts_mirror.py --check   # verify, exit 1 if short

Needs a machine that can reach fonts.gstatic.com. The web server does
not — `web/gfonts/` is copied into `build/web/` by the normal build and
shipped with it, so the mirror is served from our own origin.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import os
import re
import shutil
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "web", "gfonts")
BASE_URL = "https://fonts.gstatic.com/s/"

# Matches the string literal in each `NotoFont(...)` entry, e.g.
#   'notosanssc/v37/k3kCo84...NexQ2w.110.woff2'
_URL_RE = re.compile(r"'([a-z0-9]+/v\d+/[^']+\.woff2)'")

# woff2 files start with the signature 'wOF2'. Checked on every write
# because the failure this whole script exists to prevent — a dev server
# answering a font request with index.html — is one the engine reports
# as a corrupt font, not as a 404, and it would be a shame to bake that
# into the mirror itself.
WOFF2_MAGIC = b"wOF2"


def find_font_fallback_data() -> str:
    """Locate `font_fallback_data.dart` in the active Flutter SDK."""
    roots = []
    if os.environ.get("FLUTTER_ROOT"):
        roots.append(os.environ["FLUTTER_ROOT"])
    exe = shutil.which("flutter")
    if exe:
        # <sdk>/bin/flutter[.bat]
        roots.append(os.path.dirname(os.path.dirname(os.path.realpath(exe))))

    rel = os.path.join(
        "bin", "cache", "flutter_web_sdk", "lib", "_engine", "engine",
        "font_fallback_data.dart",
    )
    for root in roots:
        path = os.path.join(root, rel)
        if os.path.exists(path):
            return path

    raise SystemExit(
        "could not find font_fallback_data.dart in the Flutter SDK.\n"
        "Set FLUTTER_ROOT, or make sure `flutter` is on PATH and you have\n"
        "built for web at least once (the web SDK is downloaded on demand)."
    )


def fallback_urls(data_path: str) -> list[str]:
    src = open(data_path, encoding="utf8").read()
    urls = _URL_RE.findall(src)
    if not urls:
        raise SystemExit(f"no font URLs found in {data_path} — format changed?")
    # The same file can appear under more than one NotoFont entry.
    return sorted(set(urls))


def download(url_path: str) -> tuple[str, int, str | None]:
    """Fetch one font. Returns (url_path, bytes_written, error)."""
    dst = os.path.join(OUT_DIR, *url_path.split("/"))
    request = urllib.request.Request(
        BASE_URL + url_path,
        # gstatic serves woff2 only to clients that claim to support it,
        # and a bare urllib User-Agent gets a ttf (or a 403) instead.
        headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Chrome/120"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            body = response.read()
    except Exception as exc:  # network, TLS, HTTP — all equally fatal here
        return url_path, 0, str(exc)

    if not body.startswith(WOFF2_MAGIC):
        return url_path, 0, f"not a woff2 (starts with {body[:4]!r})"

    os.makedirs(os.path.dirname(dst), exist_ok=True)
    # Write to a temp name and rename, so an interrupted run leaves no
    # truncated file that the next run would count as present.
    tmp = dst + ".part"
    with open(tmp, "wb") as out:
        out.write(body)
    os.replace(tmp, dst)
    return url_path, len(body), None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="verify the mirror is complete; download nothing")
    parser.add_argument("--jobs", type=int, default=16,
                        help="parallel downloads (default 16)")
    args = parser.parse_args()

    data_path = find_font_fallback_data()
    urls = fallback_urls(data_path)
    missing = [
        u for u in urls
        if not os.path.exists(os.path.join(OUT_DIR, *u.split("/")))
    ]

    print(f"  engine font list: {len(urls)} files ({data_path})")
    print(f"  already mirrored: {len(urls) - len(missing)}")

    if args.check:
        if missing:
            print(f"\n  !! {len(missing)} missing, e.g.:")
            for u in missing[:5]:
                print(f"       {u}")
            print("\n  Every one of these is an endless 404 loop in the browser "
                  "for any\n  text that needs it. Run: "
                  "python scripts/fetch_gfonts_mirror.py")
            return 1
        print("  mirror complete.")
        return 0

    if not missing:
        print("  nothing to do.")
        return 0

    print(f"  downloading {len(missing)} ...")
    total = 0
    errors: list[tuple[str, str]] = []
    done = 0
    with concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
        for url_path, size, error in pool.map(download, missing):
            done += 1
            if error:
                errors.append((url_path, error))
            else:
                total += size
            if done % 50 == 0 or done == len(missing):
                print(f"    {done}/{len(missing)}  {total/1048576:.1f} MB")

    if errors:
        print(f"\n  {len(errors)} failed:", file=sys.stderr)
        for url_path, error in errors[:10]:
            print(f"    {url_path}: {error}", file=sys.stderr)
        print("\n  Re-run to retry — files already fetched are skipped.",
              file=sys.stderr)
        return 1

    print(f"\n  mirror: {total/1048576:.2f} MB written to web/gfonts/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
