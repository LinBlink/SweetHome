// Custom bootstrap. Flutter substitutes the two placeholders below at
// build time; everything else here is ours.
//
// The default bootstrap loads CanvasKit from www.gstatic.com and, at
// render time, pulls fallback fonts from fonts.gstatic.com. Both hosts
// are unreachable from mainland China, which for this app means a
// permanently blank page (no render engine) or tofu boxes (no glyphs).
// Building with `--no-web-resources-cdn` moves CanvasKit into our own
// bundle; `fontFallbackBaseUrl` below moves the font fallback to a
// path we serve. See the nginx snippet in docs/web-deploy.md.

{{flutter_js}}
{{flutter_build_config}}

// The hand-written splash is dismissed by `window.dismissBootSplash`,
// defined in index.html and called from Dart's first post-frame
// callback. It used to be dropped here, two requestAnimationFrame
// ticks after runApp() resolved — but CanvasKit composites off rAF as
// well and nothing orders the two, so on Safari the splash faded
// before the first frame existed and the page went blank. Dart is the
// only side that knows when something has actually been painted.

// Milestone reporting for index.html's boot progress bar. Guarded
// because this file also has to work against an index.html from an
// older deploy, which won't define it.
//
// These are the only points in the boot where we actually learn
// something: the loader script ran, the entrypoint finished
// downloading and parsing, the engine finished initialising, runApp
// resolved. The bar interpolates between them — it never invents a
// milestone — and the last step (a real painted frame) is reported
// from Dart, because that is the only side that knows.
function bootStep(index) {
  if (window.__bootProgress) window.__bootProgress(index);
}

bootStep(1);

// Where the engine looks for fonts it can't find in a registered family.
//
// `web/gfonts/` is a complete mirror of the engine's fallback set — all
// 724 files it can ask for, ~21MB — fetched by
// scripts/fetch_gfonts_mirror.py and copied into the build like any
// other file under web/. Same directory layout as fonts.gstatic.com/s/,
// which is not optional: the engine builds these paths itself.
//
// This used to answer 404 on purpose, on the theory that a glyph we
// didn't bundle should degrade to tofu rather than hang. The engine
// does not cooperate: a *failed* fallback download is never recorded,
// so the next layout of that text queues it again, and finishing a
// batch broadcasts a font-change message that re-lays out every
// paragraph in the app. One uncovered character was an unbounded loop
// of 404s, at frame rate if it sat in an animated build.
//
// It can't be closed by subsetting harder either. build_ui_fonts.py
// can see our ARB files and our Dart source; it cannot see the rare
// hanzi in a name, or the emoji in a message, that arrive from the
// server at runtime. So the fallback has to actually work — and a
// download that succeeds is one the engine remembers.
//
// The mirror covers dev and prod alike, so the two stay honest: nothing
// renders locally that wouldn't render on the real site.
var FONT_FALLBACK_BASE_URL = "/gfonts/";

_flutter.loader.load({
  // Flutter generates flutter_service_worker.js on every build but does
  // not register it unless asked. Without this, every visit re-downloads
  // the engine and the app bundle — several MB that never changed.
  // The version token is substituted at build time, so a new build
  // invalidates the old cache instead of serving it forever.
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function (engineInitializer) {
    bootStep(2);
    var engine = await engineInitializer.initializeEngine({
      // Engine-level setting, so it goes here and not in the loader's
      // `config` — passing it there silently does nothing.
      //
      // Covers both the default Roboto download and the per-script
      // fallbacks (they share one base URL internally).
      fontFallbackBaseUrl: FONT_FALLBACK_BASE_URL,
    });
    bootStep(3);
    await engine.runApp();
    // runApp resolving means the widget tree is mounted, not that
    // anything is on screen yet. The jump to 100% belongs to the
    // post-frame callback in lib/main.dart's AuthGate.
    bootStep(4);
  },
});
