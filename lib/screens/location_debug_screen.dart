import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/location_provider.dart';

/// Debug-only screen (only reachable via the bug icon in
/// `LocationScreen`'s AppBar, which is itself gated on `kDebugMode`)
/// for diagnosing "share my location" failures on a real device.
///
/// Two things it gives you that the production UI doesn't:
///  1. A live, timestamped trail of every step `LocationProvider`'s
///     capture/report pipeline took (`LocationProvider.debugLog`) —
///     which tier ran, how long it took, whether it timed out, what
///     the server said.
///  2. Raw, one-off buttons to call the underlying `Geolocator`
///     primitives directly (bypassing the tiered fallback entirely),
///     so you can isolate *which specific call* is slow/hanging/
///     failing on a given device instead of only seeing the final
///     "GPS_TIMEOUT" outcome.
///
/// Never localized on purpose — a real end user never sees this
/// screen, so it isn't worth 7 `.arb` files' worth of strings.
class LocationDebugScreen extends StatefulWidget {
  const LocationDebugScreen({super.key});

  @override
  State<LocationDebugScreen> createState() => _LocationDebugScreenState();
}

class _LocationDebugScreenState extends State<LocationDebugScreen> {
  bool _busy = false;
  Position? _lastCoords;

  /// Runs [action] with the [LocationProvider] captured up front (not
  /// re-read from `context` after an `await`, which trips the
  /// `use_build_context_synchronously` lint and — while safe here,
  /// since `State.context` stays valid across the whole widget
  /// lifetime — is more honest about the dependency each test
  /// closure actually has).
  Future<void> _run(
    String label,
    Future<void> Function(LocationProvider provider) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final provider = context.read<LocationProvider>();
    final sw = Stopwatch()..start();
    provider.debugLogRaw('[raw] $label: start');
    try {
      await action(provider);
      provider.debugLogRaw('[raw] $label: done in ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      provider.debugLogRaw(
        '[raw] $label: FAILED after ${sw.elapsedMilliseconds}ms — $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testServiceEnabled() =>
      _run('isLocationServiceEnabled', (provider) async {
        final enabled = await Geolocator.isLocationServiceEnabled();
        provider.debugLogRaw('[raw] -> enabled=$enabled');
      });

  Future<void> _testCheckPermission() =>
      _run('checkPermission', (provider) async {
        final p = await Geolocator.checkPermission();
        provider.debugLogRaw('[raw] -> permission=$p');
      });

  Future<void> _testRequestPermission() =>
      _run('requestPermission', (provider) async {
        final p = await Geolocator.requestPermission();
        provider.debugLogRaw('[raw] -> permission=$p');
      });

  /// Android 12+ "precise" vs "approximate" location grant — see the
  /// doc comment on the equivalent check in
  /// `LocationProvider._captureFix` for why this matters: a device
  /// stuck on `reduced` will time out on every GPS_PROVIDER tier no
  /// matter what else looks correct (service on, permission granted,
  /// outdoors, high accuracy requested).
  Future<void> _testLocationAccuracy() =>
      _run('getLocationAccuracy', (provider) async {
        final accuracy = await Geolocator.getLocationAccuracy();
        provider.debugLogRaw('[raw] -> accuracy=$accuracy');
      });

  Future<void> _testLastKnown({required bool forced}) => _run(
    'getLastKnownPosition(forced=$forced)',
    (provider) async {
      final pos = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: forced,
      ).timeout(const Duration(seconds: 8));
      provider.debugLogRaw(
        pos == null
            ? '[raw] -> null (no cached fix)'
            : '[raw] -> lat=${pos.latitude.toStringAsFixed(5)}, '
                  'lng=${pos.longitude.toStringAsFixed(5)}, '
                  'age=${DateTime.now().difference(pos.timestamp).inSeconds}s',
      );
    },
  );

  /// The "just get me the coordinates" button — a single direct
  /// `getCurrentPosition` call (best accuracy, forced LocationManager
  /// per this app's China-first default, no tier fallback) with a
  /// generous but bounded timeout, so a bad fix attempt still leaves
  /// the button usable again instead of hanging forever. Result is
  /// shown in a dedicated card above the log (not just buried in it)
  /// since that's the whole point of a "get coordinates now" button.
  Future<void> _getCurrentCoords() =>
      _run('getCurrentPosition (direct)', (provider) async {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          forceAndroidLocationManager: true,
          timeLimit: const Duration(seconds: 30),
        );
        if (mounted) setState(() => _lastCoords = pos);
        provider.debugLogRaw(
          '[raw] -> lat=${pos.latitude.toStringAsFixed(6)}, '
          'lng=${pos.longitude.toStringAsFixed(6)}, '
          'accuracy=${pos.accuracy.toStringAsFixed(0)}m',
        );
      });

  Future<void> _testCurrentPosition({
    required LocationAccuracy accuracy,
    required bool forced,
    required Duration timeout,
  }) => _run('getCurrentPosition(accuracy=$accuracy, forced=$forced, '
      'timeout=${timeout.inSeconds}s)', (provider) async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      forceAndroidLocationManager: forced,
      timeLimit: timeout,
    );
    provider.debugLogRaw(
      '[raw] -> lat=${pos.latitude.toStringAsFixed(5)}, '
      'lng=${pos.longitude.toStringAsFixed(5)}, '
      'accuracy=${pos.accuracy.toStringAsFixed(0)}m',
    );
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Location Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear log',
            onPressed: provider.clearDebugLog,
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusCard(provider: provider),
          if (_lastCoords != null) ...[
            const Divider(height: 1, color: AppColors.divider),
            _CoordsCard(position: _lastCoords!),
          ],
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DebugButton(
                  label: 'Get current coordinates',
                  busy: _busy,
                  onPressed: _getCurrentCoords,
                ),
                _DebugButton(
                  label: 'reportNow()',
                  busy: _busy || provider.isAttempting,
                  onPressed: () => _run('provider.reportNow()', (p) async {
                    final ok = await p.reportNow();
                    p.debugLogRaw('[raw] -> reportNow()=$ok');
                  }),
                ),
                _DebugButton(
                  label: 'isLocationServiceEnabled',
                  busy: _busy,
                  onPressed: _testServiceEnabled,
                ),
                _DebugButton(
                  label: 'checkPermission',
                  busy: _busy,
                  onPressed: _testCheckPermission,
                ),
                _DebugButton(
                  label: 'requestPermission',
                  busy: _busy,
                  onPressed: _testRequestPermission,
                ),
                _DebugButton(
                  label: 'getLocationAccuracy (precise/reduced)',
                  busy: _busy,
                  onPressed: _testLocationAccuracy,
                ),
                _DebugButton(
                  label: 'getLastKnownPosition (forced)',
                  busy: _busy,
                  onPressed: () => _testLastKnown(forced: true),
                ),
                _DebugButton(
                  label: 'getLastKnownPosition (fused)',
                  busy: _busy,
                  onPressed: () => _testLastKnown(forced: false),
                ),
                _DebugButton(
                  label: 'getCurrentPosition high/forced/25s',
                  busy: _busy,
                  onPressed: () => _testCurrentPosition(
                    accuracy: LocationAccuracy.high,
                    forced: true,
                    timeout: const Duration(seconds: 25),
                  ),
                ),
                _DebugButton(
                  label: 'getCurrentPosition lowest/forced/10s',
                  busy: _busy,
                  onPressed: () => _testCurrentPosition(
                    accuracy: LocationAccuracy.lowest,
                    forced: true,
                    timeout: const Duration(seconds: 10),
                  ),
                ),
                _DebugButton(
                  label: 'getCurrentPosition high/fused/25s',
                  busy: _busy,
                  onPressed: () => _testCurrentPosition(
                    accuracy: LocationAccuracy.high,
                    forced: false,
                    timeout: const Duration(seconds: 25),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _LogView(entries: provider.debugLog)),
        ],
      ),
    );
  }
}

/// Result of the "Get current coordinates" button — shown prominently
/// (not just as another log line) since reading raw lat/lng off a
/// scrolling log is annoying when that's the one thing you actually
/// came here for. Tap the copy icon to grab "lat,lng" for pasting
/// into a maps app to sanity-check the fix.
class _CoordsCard extends StatelessWidget {
  final Position position;
  const _CoordsCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final coords =
        '${position.latitude.toStringAsFixed(6)},'
        '${position.longitude.toStringAsFixed(6)}';
    return Container(
      width: double.infinity,
      color: AppColors.primaryLight.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$coords  (±${position.accuracy.toStringAsFixed(0)}m, '
              '${position.timestamp.toLocal()})',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy lat,lng',
            onPressed: () => Clipboard.setData(ClipboardData(text: coords)),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final LocationProvider provider;
  const _StatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final rows = <String, String>{
      'isRunning': '${provider.isRunning}',
      'isAttempting': '${provider.isAttempting}',
      'attemptCount': '${provider.attemptCount}',
      'status': '${provider.status}',
      'lastError': provider.lastError ?? '(none)',
      'lastReportAt': provider.lastReportAt?.toIso8601String() ?? '(never)',
    };
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in rows.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${e.key}: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  const _DebugButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _LogView extends StatelessWidget {
  final List<LocationDebugEntry> entries;
  const _LogView({required this.entries});

  String _fmtTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${three(t.millisecond)}';
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No log entries yet — run something above, or wait for the\n'
          'background sampling loop to tick.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final isError =
            e.message.contains('FAILED') ||
            e.message.contains('failed') ||
            e.message.contains('timed out');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_fmtTime(e.time)}  ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textHint,
                  ),
                ),
                TextSpan(
                  text: e.message,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isError ? AppColors.danger : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
