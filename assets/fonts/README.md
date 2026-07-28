# PDF export font

`ChatExportPdfService` (lib/services/chat_export_pdf_service.dart) renders
chat-history PDFs using the `pdf` package, which draws its own glyphs and has
no access to the OS's CJK system font — Chinese/Japanese/Korean text needs an
actual font file bundled into the app, or it renders as blank/missing glyphs.

To enable proper CJK rendering, add a font file here named exactly:

```
assets/fonts/NotoSansSC-Regular.ttf
```

(e.g. Noto Sans SC from Google Fonts — covers Simplified Chinese + Latin.
Traditional Chinese/Japanese/Korean/Myanmar glyphs outside that font's
coverage will still fall back to the default font's missing-glyph box until
a broader font, such as Noto Sans CJK, is used instead.)

Then add it to `pubspec.yaml`'s `flutter: assets:` list:

```yaml
flutter:
  assets:
    - assets/fonts/NotoSansSC-Regular.ttf
```

Until the file is present, `ChatExportPdfService` falls back to the `pdf`
package's built-in Latin-only font — PDFs still generate successfully with
images embedded, but CJK text will not render correctly.

## Emoji font — PDF export only

`assets/fonts/NotoEmoji-Regular.ttf` is, despite its name, **Noto Color
Emoji** (COLRv1). Verify with fontTools rather than trusting the filename:

```python
from fontTools.ttLib import TTFont
f = TTFont('assets/fonts/NotoEmoji-Regular.ttf')
print(f['name'].getDebugName(4), 'COLR' in f)   # -> Noto Color Emoji True
```

> This section used to say the opposite — that the file should be the
> monochrome "Noto Emoji", because the `pdf` package's `ttf_parser.dart`
> only draws plain `glyf` outlines. The reasoning about the parser is
> correct; the claim about the file was not, and had been wrong long
> enough that several comments elsewhere repeated it.

Its only consumer is `ChatExportPdfService`. Because the base glyphs of a
COLR font have empty `glyf` outlines, emoji drawn as pdf *text* come out
blank — so the service rasterises each one to a PNG with Flutter's
`TextPainter` and embeds that instead. The font is registered on demand
with `FontLoader` when an export runs.

It is deliberately **not** in `pubspec.yaml`'s `fonts:` section: entries
there are loaded eagerly at engine init, and 3.9MB on every first paint
is a lot to pay for a feature most sessions never open. On-screen emoji
come from the `/gfonts/` fallback mirror instead — see `docs/web-deploy.md`.
