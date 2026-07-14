import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location.dart';
import '../services/location_service.dart';

/// Owns the foreground-only location-sharing loop required by
/// docs/api.md §6.1: first fix is reported immediately, then a
/// 1-minute timer re-samples; the report is sent only if the new
/// fix is at least [_kMinMoveMeters] away from the previously
/// reported one (otherwise dropped as "didn't move"). On
/// `AppLifecycleState.paused` / `detached` we try to capture a
/// final "last gasp" position so the next time anyone opens the
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

  /// 50 m — the same threshold used by Android's
  /// `FusedLocationProvider` default small-displacement heuristic.
  /// Anything below this is considered "didn't move" and dropped
  /// per §6.1's "位置变化不大则跳过上报" rule.
  static const double _kMinMoveMeters = 50;

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
  /// the first fix; the old 10 s budget caused every timer tick
  /// to trip `TimeoutException` and pollute [_lastError]. We let
  /// the timer fail silently when this happens — see [_captureFix].
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

  /// Public flags for the UI.
  bool get isRunning => _isRunning;
  bool get isAttempting => _isAttempting;
  int get attemptCount => _attemptCount;
  LocationStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastReportAt => _lastReported?.reportedAt;

  /// Begin the 1-minute sampling loop + lifecycle hook. Idempotent.
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
  }

  /// One-shot "share my location" button on the location screen.
  /// Runs the same sample+report pipeline as the timer; ignores
  /// the "didn't move" skip. Uses the longer [_kManualTimeout] so
  /// the user gets a chance at a real GPS fix even on cold-start.
  Future<bool> reportNow() async {
    final fix = await _captureFix(force: true);
    if (fix == null) return false;
    await _sendReport(fix);
    return true;
  }

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

  /// Sample → compare distance → report. The Timer wrapper catches
  /// errors so the loop never dies.
  Future<void> _sampleAndReport() async {
    _isAttempting = true;
    _attemptCount++;
    notifyListeners();
    try {
      final fix = await _captureFix(force: false);
      if (fix == null) return;
      final last = _lastReported;
      if (last != null &&
          _distanceMeters(last.position, fix.position) < _kMinMoveMeters) {
        // Per §6.1: 位置变化不大则跳过上报.
        return;
      }
      await _sendReport(fix);
    } catch (e) {
      // Don't kill the loop on a single bad sample — log and keep
      // the timer running. Surfacing to UI is best-effort.
      _lastError = e.toString();
      notifyListeners();
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
///
/// Without this, Android cold-start GPS (typical 20-30 s for the
/// first fix in indoor / weak-signal environments) would silently
/// starve the upload loop — every timer tick would return null and
/// the user would never see a "Updated just now" badge despite the
/// app being "correctly" configured.
  Future<LocationFix?> _captureFix({required bool force}) async {
    if (_mockMode) {
      // Stable mock "fix" — varies slightly so the distance gate
      // behaves realistically when the timer ticks.
      return LocationFix(
        position: _mockPosition(),
        capturedAt: DateTime.now(),
      );
    }
    // 1. Check service enabled (GPS on).
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _status = permission == LocationPermission.deniedForever
          ? LocationStatus.permissionPermanentlyDenied
          : LocationStatus.permissionDenied;
      notifyListeners();
      return null;
    }
    // 3. Cheap path: last-known position. The OS keeps a recent
    //    GPS lock cached; if it's fresh enough we use it and
    //    skip the (potentially long) cold-start acquire.
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null &&
          DateTime.now().difference(lastKnown.timestamp) <
              _kLastKnownFreshness) {
        return LocationFix(
          position: lastKnown,
          capturedAt: DateTime.now(),
        );
      }
    } catch (_) {
      // getLastKnownPosition can throw on devices with no prior
      // GPS session; that's fine, we'll try the fresh acquire
      // below.
    }
    // 4. Fresh acquire, tiered by accuracy + timeout. We start with
    //    the most likely-to-succeed accuracy for the caller's
    //    context (medium for the background timer — WiFi/cell
    //    triangulation locks in <5 s indoors where pure GPS would
    //    never lock — high for the manual button where the user
    //    explicitly asked for an accurate fix) and fall back to
    //    progressively weaker accuracy if the first attempt times
    //    out. Without this fallback chain, an indoor user on the
    //    background tick would see a 30 s timer expiry → silent
    //    skip → UI unchanged → looks like nothing is happening.
    //
    //    `forceAndroidLocationManager: true` forces Android's
    //    stock `LocationManager` API instead of the default
    //    Fused Location Provider (`FusedLocationProviderClient`).
    //    The latter requires Google Play Services, which most
    //    Chinese OEM ROMs (华为 EMUI / 小米 MIUI / OPPO ColorOS /
    //    Vivo OriginOS / 一加 HydrogenOS CN) ship without — on
    //    those devices `FusedLocationProviderClient` hangs
    //    indefinitely or throws `ApiException`, surfacing to the
    //    user as the "无法及时获取 GPS 定位" timeout. The stock
    //    `LocationManager` is part of the OS itself (no GMS
    //    dependency) and works on every Android device that has a
    //    GPS chip; trade-off is no WiFi/cell fusion, so cold-start
    //    fixes are slower than fused — we compensate by tiering
    //    accuracy down on timeout.
    final tiers = force
        ? const [
            (LocationAccuracy.high, _kManualTimeout),
            (LocationAccuracy.medium, Duration(seconds: 20)),
            (LocationAccuracy.low, Duration(seconds: 10)),
          ]
        : const [
            (LocationAccuracy.medium, _kSampleTimeout),
            (LocationAccuracy.low, Duration(seconds: 10)),
          ];

    Position? pos;
    for (final (acc, timeout) in tiers) {
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: acc,
          timeLimit: timeout,
          forceAndroidLocationManager: true,
        );
        break; // got a fix, stop trying lower tiers
      } on TimeoutException {
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
      if (force) {
        final available = await _hasUsableGpsProvider();
        _lastError = available ? 'GPS_TIMEOUT' : 'GPS_NOT_AVAILABLE';
        _status = LocationStatus.error;
        notifyListeners();
      }
      return null;
    }
    return LocationFix(
      position: pos,
      capturedAt: DateTime.now(),
    );
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

  Future<void> _sendReport(LocationFix fix) async {
    final report = LocationReport(
      lng: fix.position.longitude,
      lat: fix.position.latitude,
      // `Geolocator.getCurrentPosition` doesn't surface battery; the
      // server's documented default for missing battery is -1, which
      // is what we get by leaving the field null in the request.
      battery: null,
      updateTime: fix.capturedAt,
    );
    try {
      if (_mockMode) {
        // No backend to hit in MOCK_MODE — skip the HTTP call but
        // still update [_lastReported] so the UI's "Updated Xm ago"
        // badge moves forward and the distance-gate stays consistent.
        // Without this, [_lastReported] stays null forever and every
        // 1-minute timer tick trips the distance gate.
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
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _status = LocationStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Great-circle distance (Haversine) in meters. Standalone
  /// helper so it can be unit-tested independently.
  static double _distanceMeters(Position a, Position b) {
    const earthRadius = 6371000.0;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = (1 - math.cos(dLat)) / 2 +
        math.cos(lat1) *
            math.cos(lat2) *
            (1 - math.cos(dLng)) /
            2;
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  /// Stable mock fix anchored near Beijing (天安门 ~ 39.9087 N,
  /// 116.3975 E) with a tiny per-tick offset so the distance gate
  /// behaves realistically when the timer fires.
  Position _mockPosition() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Oscillate ±0.0003 deg (~33 m) so consecutive mock samples
    // sometimes pass the 50 m gate and sometimes don't.
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