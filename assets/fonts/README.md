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

## Emoji font — use the monochrome variant, not the color one

`assets/fonts/NotoEmoji-Regular.ttf` should be the **monochrome** build
("Noto Emoji", not "Noto Color Emoji"). Download the static TTF from Google
Fonts:

```
https://fonts.google.com/noto/specimen/Noto+Emoji
```

The `pdf` package's font parser (`ttf_parser.dart`) renders standard TrueType
outline (`glyf`) glyphs reliably, but colour formats (COLR/CPAL, CBDT/CBLC,
SVG) need special handling that the parser's limited bitmap path doesn't
always support. The monochrome variant uses plain outline glyphs in the `glyf`
table, which render correctly in black/white — standard for document exports.
