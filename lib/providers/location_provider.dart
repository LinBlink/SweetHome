import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../services/location_service.dart';

/// Owns the foreground-only location-sharing loop required by
/// docs/api.md §6.1: first fix is reported immediately, then a
/// ~1-minute timer re-samples and reports *every* successful fix —
/// the spec has no distance/displacement gate, so don't add one (an
/// earlier version of this file did, and it silently killed all
/// periodic reports after the first once the user stopped moving —
/// see git history / AGENTS.md for the postmortem). On
/// `AppLifecycleState.paused` / `detached` we try to capture a final
/// "last gasp" position so the next time anyone opens the
/// family-location screen they see something close to where the
/// user was when they left.
///
/// The provider does not own `LocationScreen`'s fetch path — the
/// screen calls `LocationService.fetchFamilyLocations()` directly
/// and renders the result. This provider only drives the *upload*
/// side of the feature.
class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  LocationProvider({required LocationService service, required bool mockMode})
    : _service = service,
      _mockMode = mockMode;

  final LocationService _service;
  final bool _mockMode;

  /// Sample cadence — the spec (§6.1) says "约每分钟" (about every
  /// minute). We use 30 s rather than 60 s because in practice
  /// Android cold-start GPS often only locks after 20-30 s, so the
  /// user otherwise sees their first report 60+ seconds after
  /// opening the screen instead of ~30 s. After the first
  /// successful report the cadence is fine; the slightly tighter
  /// tick is invisible once GPS is warm.
  static const Duration _kSampleInterval = Duration(seconds: 30);

  /// 30 s for the background tick. Android cold-start GPS in
  /// indoor / weak-signal environments routinely takes 20-30 s for
  /// the first fix; a shorter budget causes every timer tick to
  /// trip `TimeoutException` and pollute [_lastError]. We let the
  /// timer fail silently when this happens — see [_captureFix].
  static const Duration _kSampleTimeout = Duration(seconds: 30);

  /// 60 s for the manual "Share my location" button — user-initiated,
  /// they're willing to wait longer for an accurate fix.
  static const Duration _kManualTimeout = Duration(seconds: 60);

  /// 5 minutes — the freshness window for falling back to
  /// `Geolocator.getLastKnownPosition()`. Android's last-known
  /// cache is reasonably fresh for a few minutes even in
  /// cold-start / indoor scenarios, so reporting a 2-3 minute
  /// old fix is better than reporting nothing (which is what
  /// happens when `getCurrentPosition` keeps timing out).
  static const Duration _kLastKnownFreshness = Duration(minutes: 5);

  Timer? _timer;
  LocationFix? _lastReported;
  bool _isRunning = false;
  bool _isAttempting = false;
  int _attemptCount = 0;
  LocationStatus _status = LocationStatus.idle;
  String? _lastError;
  final List<LocationDebugEntry> _debugLog = [];

  /// Public flags for the UI.
  bool get isRunning => _isRunning;
  bool get isAttempting => _isAttempting;
  int get attemptCount => _attemptCount;
  LocationStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastReportAt => _lastReported?.reportedAt;

  /// Newest-first trail of every step `_captureFix`/`_sendReport` took
  /// (permission checks, each tier's accuracy/timeout/outcome, report
  /// send result). Exists purely for `LocationDebugScreen` — nothing
  /// in the production UI reads this. Capped so a long-running session
  /// doesn't leak memory.
  List<LocationDebugEntry> get debugLog => List.unmodifiable(_debugLog);

  void _log(String message) {
    _debugLog.insert(0, LocationDebugEntry(DateTime.now(), message));
    if (_debugLog.length > 200) {
      _debugLog.removeRange(200, _debugLog.length);
    }
    notifyListeners();
  }

  /// For `LocationDebugScreen`'s "Clear log" button.
  void clearDebugLog() {
    _debugLog.clear();
    notifyListeners();
  }

  /// Lets `LocationDebugScreen` append its own raw-primitive test
  /// results (e.g. a standalone `Geolocator.getCurrentPosition` call
  /// outside the normal tiered pipeline) into the same chronological
  /// log as `_captureFix`/`_sendReport`, instead of keeping a second,
  /// separate log widget.
  void debugLogRaw(String message) => _log(message);

  /// Persisted on/off flag so the sharing toggle survives an app
  /// restart (process kill, not just backgrounding) — without this
  /// the toggle only lives as long as `LocationProvider` does, which
  /// is the login session's in-memory lifetime, so a fresh cold start
  /// always looked "off" even if the user had just turned it on.
  static const String _kSharingPrefsKey = 'location_sharing_enabled';

  /// Call once right after construction (see `main.dart`) to resume
  /// sharing if it was on when the app was last closed.
  Future<void> restoreSharingState() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSharingPrefsKey) ?? false) {
      await startSharing();
    }
  }

  Future<void> _persistSharingState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSharingPrefsKey, enabled);
  }

  /// Begin the ~1-minute sampling loop + lifecycle hook. Idempotent.
  /// The first sample is reported immediately per §6.1
  /// ("首次采集必定上报").
  Future<void> startSharing() async {
    if (_isRunning) return;
    _isRunning = true;
    _status = LocationStatus.running;
    notifyListeners();
    WidgetsBinding.instance.addObserver(this);
    // First fix is mandatory.
    unawaited(_sampleAndReport());
    _timer = Timer.periodic(_kSampleInterval, (_) => _sampleAndReport());
    unawaited(_persistSharingState(true));
  }

  /// Cancel the loop and detach the lifecycle hook. Safe to call
  /// multiple times.
  void stopSharing() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _status = LocationStatus.idle;
    WidgetsBinding.instance.removeObserver(this);
    notifyListeners();
    // Also covers logout: `dispose()` calls `stopSharing()`, so a
    // different user logging in later on the same device doesn't
    // inherit a previous account's sharing preference.
    unawaited(_persistSharingState(false));
  }

  /// Flip between [startSharing] and [stopSharing]. Bound to the
  /// share-toggle `Switch` on the location screen. Disabled while a
  /// sample is in flight so the user can't toggle off mid-GPS-fix
  /// (which would orphan the in-flight `_sampleAndReport` future and
  /// surface a confusing half-applied report on next mount).
  void toggleSharing() {
    if (_isAttempting) return;
    if (_isRunning) {
      stopSharing();
    } else {
      startSharing();
    }
  }

  /// One-shot "share my location" button on the location screen.
  /// Runs the same sample+report pipeline as the timer (via
  /// [_attemptSample]) with `force: true`, which uses the longer
  /// [_kManualTimeout] so the user gets a chance at a real GPS fix
  /// even on cold-start.
  Future<bool> reportNow() => _attemptSample(force: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning) return;
    // §6.1 "GPS 关闭或 App 被强制退出前补发最后一次定位": the OS
    // gives us a `paused` callback as the user backgrounds the app,
    // and (on Android, with the right config) a `detached` callback
    // just before the process dies. We treat both as "last gasp"
    // and try to capture one more fix.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      unawaited(_sampleAndReport());
    }
  }

  /// Background-timer entry point — same pipeline as [reportNow], just
  /// `force: false`. Kept as a separate method (instead of pointing
  /// `Timer.periodic` straight at `_attemptSample`) so its `void`
  /// return type doesn't leak `_attemptSample`'s bool into the
  /// `Timer.periodic` callback signature.
  Future<void> _sampleAndReport() async {
    // The background tier budget (up to ~45s: `_kSampleTimeout` 30s +
    // lowest-tier 10s + 5s last-known check) can exceed the 30s timer
    // interval, so a slow/indoor fix can still be in flight when the
    // next tick fires. Skip that tick rather than starting a second
    // concurrent `_attemptSample`, which would race on `_isAttempting`/
    // `_lastReported`/etc. and could double-report.
    if (_isAttempting) return;
    await _attemptSample(force: false);
  }

  /// Sample → report, shared by the background timer and the manual
  /// "Share my location" button. §6.1 only specifies "约每分钟采集一次"
  /// — there is no server-side or documented distance gate, so every
  /// successful sample is reported. Errors are caught here (not
  /// rethrown) so:
  ///  - the background `Timer` never dies on a single bad sample —
  ///    the loop just tries again on the next tick.
  ///  - the manual button gets a clean `false` return instead of an
  ///    exception escaping uncaught through its `onPressed` (an
  ///    earlier version of this file didn't catch `_sendReport`'s
  ///    rethrow here, so a failed manual report threw all the way up
  ///    with no UI feedback at all).
  /// `_isAttempting` is set for the *entire* call, including the
  /// manual path — without this the "Locating…" status line and any
  /// other `isAttempting`-driven UI stay frozen for the whole
  /// multi-tier timeout window (up to 90s), which looks exactly like
  /// the button did nothing until the error toast finally appears.
  Future<bool> _attemptSample({required bool force}) async {
    _isAttempting = true;
    _attemptCount++;
    _log('${force ? "manual" : "background"} attempt #$_attemptCount start');
    notifyListeners();
    try {
      final fix = await _captureFix(force: force);
      if (fix == null) return false;
      await _sendReport(fix);
      return true;
    } catch (e) {
      _lastError = e.toString();
      _log('attempt failed: $e');
      notifyListeners();
      return false;
    } finally {
      _isAttempting = false;
      notifyListeners();
    }
  }

  /// Permission flow + actual `Geolocator.getCurrentPosition` (or a
  /// mock position in MOCK_MODE). Sets [_status] appropriately so
  /// the UI can prompt the user.
  ///
  /// Two-stage capture strategy on real devices:
  /// 1. Try `Geolocator.getLastKnownPosition()` — instant, doesn't
  ///    require an active GPS lock. If the cached fix is younger than
  ///    [_kLastKnownFreshness], use it directly.
  /// 2. Otherwise fall through to `Geolocator.getCurrentPosition()`
  ///    with [_kSampleTimeout] (background) or [_kManualTimeout]
  ///    (manual button). On timeout, the background loop returns
  ///    null silently (the next tick will try again); the manual
  ///    call sets a machine-readable error code so the UI can
  ///    surface a localized message.
  Future<LocationFix?> _captureFix({required bool force}) async {
    if (_mockMode) {
      // Stable mock "fix" that varies slightly per tick so the UI's
      // coordinates/timestamp visibly move between reports.
      _log('mock mode: returning synthetic fix');
      return LocationFix(position: _mockPosition(), capturedAt: DateTime.now());
    }
    // 1. Check service enabled (GPS on).
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    _log('isLocationServiceEnabled=$serviceEnabled');
    if (!serviceEnabled) {
      _status = LocationStatus.gpsOff;
      // Also surface a machine-readable error code so the manual
      // "Share my location" button can show a localized message
      // (the GPS-off path is silent in the background timer, but
      // the user-initiated call should not be).
      if (force) {
        _lastError = 'GPS_OFF';
      }
      notifyListeners();
      return null;
    }
    // 2. Check / request permission.
    var permission = await Geolocator.checkPermission();
    _log('checkPermission=$permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      _log('requestPermission=$permission');
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = permission == LocationPermission.deniedForever
          ? LocationStatus.permissionPermanentlyDenied
          : LocationStatus.permissionDenied;
      notifyListeners();
      return null;
    }
    // Android 12+ (API 31+) lets the user grant "approximate location"
    // instead of "precise" — `checkPermission`/`requestPermission`
    // above still report the permission as granted either way, so
    // this is easy to miss. With only reduced accuracy granted, every
    // GPS_PROVIDER request below can time out indefinitely no matter
    // how long the budget is, because the OS simply won't hand fine
    // fixes to an app that only asked for (or was only given)
    // approximate location — this is diagnostic-only for now (logged,
    // not acted on) since there's no in-app API on Android to
    // re-prompt for precise-only; fixing it requires the user to flip
    // "Use precise location" in system Settings > Apps > this app.
    try {
      final accuracy = await Geolocator.getLocationAccuracy();
      _log('getLocationAccuracy=$accuracy');
    } catch (e) {
      _log('getLocationAccuracy failed: $e');
    }
    // 3. Cheap path: last-known position. The OS keeps a recent
    //    GPS lock cached; if it's fresh enough we use it and
    //    skip the (potentially long) cold-start acquire.
    //
    //    `forceAndroidLocationManager: true` here too — see the
    //    step-4 comment for why this app defaults to the GMS-free
    //    path everywhere on Android instead of trying Google Play
    //    Services first. This call also has no `timeLimit` of its
    //    own (bare method-channel invoke, no native-side timeout),
    //    so a hang would otherwise leave this `await` — and the
    //    whole capture/report pipeline — stuck forever (surfaced to
    //    the user as "Locating…" never resolving); bound it
    //    explicitly so a hang always falls through to step 4.
    try {
      final lastKnown = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: true,
      ).timeout(const Duration(seconds: 5));
      if (lastKnown == null) {
        _log('getLastKnownPosition: no cached fix');
      } else {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age < _kLastKnownFreshness) {
          _log(
            'getLastKnownPosition: using cached fix (age=${age.inSeconds}s)',
          );
          return LocationFix(position: lastKnown, capturedAt: DateTime.now());
        }
        _log(
          'getLastKnownPosition: cached fix too stale (age=${age.inSeconds}s)',
        );
      }
    } catch (e) {
      // getLastKnownPosition can throw (no prior GPS session) or
      // time out (see above); either way fall through to the timed
      // fresh-acquire tiers below.
      _log('getLastKnownPosition: failed/timed out ($e)');
    }
    // 4. Fresh acquire, tiered by accuracy + timeout. Every tier sets
    //    `forceAndroidLocationManager: true` — this app targets
    //    mainland China users, where Google Play Services is
    //    essentially never present (Google services are unavailable
    //    there), so the default Fused Location Provider
    //    (`FusedLocationProviderClient`) would hang or throw
    //    `ApiException` on virtually every real device in the target
    //    market. Trying it "first, for speed" (an earlier version of
    //    this file did) means every single acquisition burns a whole
    //    tier's timeout on a call that is essentially guaranteed to
    //    fail for this audience before ever reaching the method that
    //    actually works. The stock `LocationManager` API has no GMS
    //    dependency and works on every Android device with a GPS
    //    chip — and per `geolocator_android`'s own provider-selection
    //    logic (`LocationManagerClient.determineProvider`), on
    //    Android 12+ (API 31+) it transparently uses the OS-native
    //    `FUSED_PROVIDER` (WiFi/cell fusion, no GMS involved) when
    //    available, so forcing it isn't even an accuracy trade-off on
    //    modern devices — only pre-12 / no-native-fused devices fall
    //    back to raw GPS_PROVIDER satellite fixes.
    //
    //    The tiers still fall back by accuracy on timeout (an indoor
    //    user needs a chance at *some* fix, not silence), and the
    //    final tier uses `LocationAccuracy.lowest`, which is the only
    //    accuracy value that maps to `PASSIVE_PROVIDER` — a genuinely
    //    different, near-instant provider that returns whatever
    //    position any other app/service on the device most recently
    //    requested, rather than GPS_PROVIDER again (forced
    //    `LocationManager` maps every *other* accuracy tier to
    //    GPS_PROVIDER once it's enabled, so `lowest` is the only tier
    //    that actually diversifies the fallback chain instead of
    //    retrying the same satellite fix with a shorter timeout).
    final tiers = force
        ? const [
            (LocationAccuracy.high, _kManualTimeout),
            (LocationAccuracy.medium, Duration(seconds: 20)),
            (LocationAccuracy.lowest, Duration(seconds: 10)),
          ]
        : const [
            (LocationAccuracy.medium, _kSampleTimeout),
            (LocationAccuracy.lowest, Duration(seconds: 10)),
          ];

    Position? pos;
    for (final (acc, timeout) in tiers) {
      final sw = Stopwatch()..start();
      _log('tier acc=$acc timeout=${timeout.inSeconds}s: requesting…');
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: acc,
          timeLimit: timeout,
          forceAndroidLocationManager: true,
        );
        _log(
          'tier acc=$acc: fix in ${sw.elapsedMilliseconds}ms '
          '(lat=${pos.latitude.toStringAsFixed(5)}, '
          'lng=${pos.longitude.toStringAsFixed(5)}, '
          'accuracy=${pos.accuracy.toStringAsFixed(0)}m)',
        );
        break; // got a fix, stop trying lower tiers
      } on TimeoutException {
        _log('tier acc=$acc: timed out after ${sw.elapsedMilliseconds}ms');
        // Try the next tier.
        continue;
      }
    }
    if (pos == null) {
      // Every tier timed out. Distinguish two scenarios for the
      // manual button so the UI can give actionable guidance:
      //  - GPS_TIMEOUT: just slow / indoors — try outdoors
      //  - GPS_NOT_AVAILABLE: device genuinely has no usable GPS
      //    provider (no GPS hardware, mock location stealing the
      //    lock, OEM "privacy protection" blocking). Detection
      //    via a quick second check isLocationServiceEnabled +
      //    check that we got at least one location provider.
      _log('all tiers exhausted with no fix');
      if (force) {
        final available = await _hasUsableGpsProvider();
        _lastError = available ? 'GPS_TIMEOUT' : 'GPS_NOT_AVAILABLE';
        _status = LocationStatus.error;
        notifyListeners();
      }
      return null;
    }
    return LocationFix(position: pos, capturedAt: DateTime.now());
  }

  /// Best-effort diagnostic for "why is GPS not working". True
  /// when system reports at least one enabled location provider.
  /// False covers devices without GPS hardware, mock-location
  /// apps stealing the fix, and Chinese OEM "privacy protection"
  /// silently blocking access.
  Future<bool> _hasUsableGpsProvider() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      return enabled;
    } catch (_) {
      return true; // assume OK if the check itself blows up
    }
  }

  /// Reads the host phone's battery level for inclusion in the
  /// §6.1 report payload. Returns `null` when:
  ///  - the platform has no battery API (desktop / web — `battery_plus`
  ///    surfaces -1 there),
  ///  - the OS denies the read (e.g. Chrome blocks the Battery API
  ///    when the document isn't user-gesture-originated),
  ///  - we're in MOCK_MODE and want a believable 78→74% drain
  ///    curve instead of fake -1.
  ///
  /// Docs/api.md §6.1: "battery 超过 100 → 400 LOCATION_BATTERY_INVALID"
  /// so we clamp defensively before sending.
  Future<int?> _readBatteryPercent() async {
    if (_mockMode) {
      // Stable mock "battery" with a slow downward drift so the
      // mock dashboard's battery pill doesn't look frozen between
      // reports. Range 78%..74% over ~10 minutes.
      final pct = 78 - ((DateTime.now().millisecondsSinceEpoch ~/ 60000) % 5);
      return pct;
    }
    try {
      final raw = await Battery().batteryLevel;
      // `battery_plus` uses -1 as the sentinel for "no battery API on
      // this platform" on most platforms (headless test, some
      // desktop targets). Surface that to the server the same way the
      // API docs prescribe — leave `battery` null on the request so
      // the server records -1.
      //
      // Web is a different story: `battery_plus_web` returns `0` (not
      // -1) when `navigator.getBattery()` is unavailable (Safari,
      // Firefox, or a Chrome context without a user gesture) — see
      // `battery_plus_web.dart`'s `batteryLevel` getter. Since this
      // app explicitly targets Web, treating `0` as "actually 0%" on
      // that platform would misreport "no battery API" as "phone is
      // dead" on the family dashboard. Real devices at a genuine 0%
      // are effectively powered off and won't be actively reporting
      // anyway, so folding `0` into the "unknown" case on web is a
      // safe trade.
      if (kIsWeb ? raw <= 0 : raw < 0) return null;
      // Defensive clamp: server rejects > 100 with 400
      // LOCATION_BATTERY_INVALID. Some devices report 101-105 in
      // the brief moment after coming off a charger.
      return raw.clamp(0, 100);
    } catch (e) {
      _log('battery read failed: $e');
      return null;
    }
  }

  Future<void> _sendReport(LocationFix fix) async {
    // Per docs/api.md §6.1: `battery` is optional; if we can't read
    // it (web, unsupported platform, OS denies) we leave it null and
    // the server stores `-1` as its sentinel for "unknown".
    // Re-read on every report (no caching) so the value reflects
    // the phone's actual state at send-time — accurate enough for
    // the family's at-a-glance dashboard and cheap (~10 ms on
    // Android via a sticky Binder call into BatteryService).
    final battery = await _readBatteryPercent();
    final report = LocationReport(
      lng: fix.position.longitude,
      lat: fix.position.latitude,
      battery: battery,
      updateTime: fix.capturedAt,
    );
    _log(
      'reporting lat=${report.lat.toStringAsFixed(5)}, '
      'lng=${report.lng.toStringAsFixed(5)}, '
      'battery=${battery ?? -1}, '
      'updateTime=${report.updateTime.toIso8601String()}',
    );
    try {
      if (_mockMode) {
        // No backend to hit in MOCK_MODE — skip the HTTP call but
        // still update [_lastReported] so the UI's "Updated Xm ago"
        // badge moves forward and behaves consistently with the real
        // path. Without this, [_lastReported] stays null forever.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } else {
        await _service.reportPosition(report);
      }
      _lastReported = LocationFix(
        position: fix.position,
        capturedAt: fix.capturedAt,
        reportedAt: DateTime.now(),
      );
      _status = LocationStatus.running;
      _lastError = null;
      _log('report OK');
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _status = LocationStatus.error;
      _log('report failed: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Stable mock fix anchored near Beijing (天安门 ~ 39.9087 N,
  /// 116.3975 E) with a tiny per-tick offset so consecutive reports
  /// aren't at the exact same point.
  Position _mockPosition() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final offset = (now ~/ 1000) % 100;
    return Position(
      longitude: 116.3975 + (offset - 50) * 0.00003,
      latitude: 39.9087 + ((offset * 7) % 100 - 50) * 0.00003,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  void dispose() {
    stopSharing();
    super.dispose();
  }
}

/// Public status the UI renders against.
enum LocationStatus {
  /// Not currently sharing (initial / stopped).
  idle,

  /// Sampling and reporting on the 1-minute timer.
  running,

  /// Permission denied for this session; user can re-grant via the
  /// in-app button.
  permissionDenied,

  /// Permission denied with `deniedForever`; the only fix is the
  /// system settings page.
  permissionPermanentlyDenied,

  /// Service disabled (GPS toggle off in system).
  gpsOff,

  /// Last report call failed; [lastError] holds the message.
  error,
}

/// Captured fix + the moment we successfully reported it. Internal —
/// not exported.
class LocationFix {
  final Position position;
  final DateTime capturedAt;
  final DateTime? reportedAt;
  const LocationFix({
    required this.position,
    required this.capturedAt,
    this.reportedAt,
  });
}

/// One timestamped step in `LocationProvider`'s capture/report
/// pipeline. See `LocationProvider.debugLog` / `LocationDebugScreen`.
class LocationDebugEntry {
  final DateTime time;
  final String message;
  const LocationDebugEntry(this.time, this.message);
}
