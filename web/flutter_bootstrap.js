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
    var engine = await engineInitializer.initializeEngine({
      // Engine-level setting, so it goes here and not in the loader's
      // `config` — passing it there silently does nothing.
      //
      // Covers both the default Roboto download and the per-script
      // fallbacks (they share one base URL internally). Must keep
      // fonts.gstatic.com/s/'s directory layout — see the nginx
      // `location /gfonts/` block, which proxies and caches upstream
      // rather than mirroring the files by hand.
      fontFallbackBaseUrl: "/gfonts/",
    });
    await engine.runApp();
  },
});
