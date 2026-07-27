#!/usr/bin/env python3
"""Pre-compress build/web so nginx can serve .br/.gz without re-doing
the work on every request.

On-the-fly compression of a 5.9MB main.dart.js is both slow and, at
nginx's default gzip level, worse than what we can afford to spend
offline: brotli quality 11 takes seconds per file but happens once per
deploy, and cuts the first load roughly in half again versus gzip.

nginx serves these automatically via `brotli_static on` / `gzip_static
on` — it looks for `<file>.br` and `<file>.gz` next to the original and
picks one based on the request's Accept-Encoding. Clients that support
neither still get the plain file, so this degrades cleanly.

Usage:  python scripts/precompress_web.py [build/web]
"""

from __future__ import annotations

import gzip
import os
import sys

# Anything already entropy-coded (png, jpg, woff2, ico) is skipped —
# recompressing costs deploy time and produces a larger file, which
# nginx would then dutifully serve.
COMPRESSIBLE = {
    ".js", ".mjs", ".json", ".html", ".css", ".wasm", ".svg",
    ".ttf", ".otf", ".map", ".txt", ".xml",
}

# Below this, framing overhead and an extra stat() outweigh the saving.
MIN_BYTES = 1024

try:
    import brotli
    HAVE_BROTLI = True
except ImportError:
    HAVE_BROTLI = False


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(__file__), "..", "build", "web"
    )
    if not os.path.isdir(root):
        print(f"not a directory: {root}", file=sys.stderr)
        return 1

    if not HAVE_BROTLI:
        print("  note: `pip install brotli` for ~25% smaller than gzip\n")

    raw = gz = br = 0
    count = 0
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            if name.endswith((".gz", ".br")):
                continue
            if os.path.splitext(name)[1].lower() not in COMPRESSIBLE:
                continue
            path = os.path.join(dirpath, name)
            data = open(path, "rb").read()
            if len(data) < MIN_BYTES:
                continue

            gz_bytes = gzip.compress(data, 9)
            open(path + ".gz", "wb").write(gz_bytes)

            br_bytes = b""
            if HAVE_BROTLI:
                br_bytes = brotli.compress(data, quality=11)
                open(path + ".br", "wb").write(br_bytes)

            raw += len(data)
            gz += len(gz_bytes)
            br += len(br_bytes) if br_bytes else len(gz_bytes)
            count += 1

    print(f"  {count} files: {raw/1048576:.1f} MB raw")
    print(f"    gzip   -> {gz/1048576:.1f} MB")
    if HAVE_BROTLI:
        print(f"    brotli -> {br/1048576:.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
