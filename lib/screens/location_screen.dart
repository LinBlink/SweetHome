import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/address_resolver.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';
import 'location_debug_screen.dart';
import 'location_fullscreen_screen.dart';

/// API §6 实时位置 page. Layout (top to bottom):
///   1. OSM map with one avatar-marker per member with a fresh fix
///   2. Stats strip: "{online}/{total} sharing location"
///   3. Member list: avatar + name + battery + lng/lat + "Xm ago"
///   4. Permission / GPS-off banners, when relevant
///   5. "Share my location" action (initiates the upload loop)
///
/// Map data comes from [LocationService.fetchFamilyLocations]; the
/// upload loop is owned by [LocationProvider] which the screen
/// instantiates on mount so the user's own position gets reported
/// per §6.1's "首次采集 + 每分钟一次 + 退出前补发" cadence.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late final LocationService _service;
  Future<FamilyLocations>? _future;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    // Sharing itself isn't auto-started here — `LocationProvider` is
    // app-scoped (provided in `main.dart`, alongside `ChatProvider`)
    // so it already reflects whatever on/off state the user last set,
    // even if that was on a previous visit to this screen. We still
    // eagerly load the family locations because that's a *read* path
    // that shows the map markers — independent of whether the local
    // user is sharing.
    _future = _loadLocations();
  }

  Future<FamilyLocations> _loadLocations() {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.mockFamilyLocations());
    }
    return _service.fetchFamilyLocations();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadLocations());
    await _future;
  }

  /// Push a dedicated fullscreen-map screen. We don't gate the
  /// push on `_future` having completed — if the user taps
  /// fullscreen while the initial family-locations fetch is still
  /// in flight, the fullscreen screen owns its own `FutureBuilder`
  /// and re-issues the fetch.
  void _openFullscreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const LocationFullscreenScreen()),
    );
  }

  /// Wire the toggle switch: ON starts the §6.1 background loop,
  /// OFF cancels it. The provider's `toggleSharing()` itself guards
  /// against mid-sample toggles (`isAttempting` short-circuits the
  /// call), so we don't need extra state here.
  void _onToggleSharing() {
    context.read<LocationProvider>().toggleSharing();
  }

  /// Compute the initial camera fit BEFORE FlutterMap is built, so
  /// the very first frame already has the right viewport. Calling
  /// [_mapController.fitCamera] from a post-frame callback (the
  /// older approach) introduces a race: FlutterMap mounts with the
  /// default camera, paints one frame, then we jump the camera to
  /// the marker bounds mid-frame — at which point the TileLayer
  /// has to re-issue tile requests for the new viewport, racing
  /// against the MarkerLayer overlay's first paint, and on Web in
  /// particular the result is the map blank with markers visible
  /// until the user drags (a gesture event nudges the rendering
  /// pipeline and the in-flight tiles finish). Setting
  /// `initialCameraFit` skips that whole intermediate state —
  /// markers + tiles both render in their correct positions on
  /// frame 1.
  MapOptions _initialOptions(List<MemberLocation> members) {
    if (members.isEmpty) {
      return MapOptions(
        initialCenter: const LatLng(39.9087, 116.3975),
        initialZoom: 11,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      );
    }
    if (members.length == 1) {
      return MapOptions(
        initialCenter: LatLng(members.first.lat, members.first.lng),
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      );
    }
    final bounds = LatLngBounds.fromPoints(
      members.map((m) => LatLng(m.lat, m.lng)).toList(),
    );
    return MapOptions(
      initialCameraFit: CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
      minZoom: 3,
      maxZoom: 18,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // LocationProvider is app-scoped (provided in main.dart alongside
    // ChatProvider), not owned by this screen, so `_ProviderBanner`,
    // `_ShareToggle`, `_LastReportedLine` below can `context.watch` it
    // directly without a local `ChangeNotifierProvider.value` wrapper.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.locationTitle),
        actions: [
          // Debug-build-only entry to the raw capture/report log —
          // never shown in a release build, so no l10n needed for
          // a screen a real user will never see.
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // `Navigator.push` inserts the new route as a
                  // sibling of this screen's own provider scope, not
                  // a descendant of it, so LocationProvider has to be
                  // re-provided explicitly here (same pattern used
                  // for ChatProvider elsewhere in this app).
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<LocationProvider>(),
                    child: const LocationDebugScreen(),
                  ),
                ),
              ),
              tooltip: 'Location debug',
            ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () => _openFullscreen(),
            tooltip: l10n.locationFullscreen,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: l10n.locationRefresh,
          ),
        ],
      ),
      body: FutureBuilder<FamilyLocations>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            final isApi = snapshot.error is ApiException;
            return ErrorBanner(
              message: localizeErrorMessage(
                isApi
                    ? (snapshot.error as ApiException).message
                    : kNetworkErrorSentinel,
                l10n,
              ),
              onDismiss: _refresh,
            );
          }
          final data = snapshot.data!;
          final members = data.familyMemberLocations;
          return Column(
            children: [
              _MapPanel(
                members: members,
                mapController: _mapController,
                options: _initialOptions(members),
              ),
              _StatsStrip(data: data, l10n: l10n),
              _ProviderBanner(),
              const Divider(height: 1, color: AppColors.divider),
              Expanded(
                child: members.isEmpty
                    ? _EmptyState(l10n: l10n, total: data.totalMemberCount)
                    : ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 70),
                        itemBuilder: (_, i) =>
                            _MemberTile(member: members[i], l10n: l10n),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LastReportedLine(),
                      const SizedBox(height: 8),
                      _ShareToggle(onChanged: _onToggleSharing),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  final List<MemberLocation> members;
  final MapController mapController;
  final MapOptions options;

  const _MapPanel({
    required this.members,
    required this.mapController,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: options,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'asia.sweethome.flutter',
                maxZoom: 19,
                // Default `TileDisplay.fadeIn()` starts each tile at
                // opacity 0 and only reveals it once a 100ms
                // AnimationController finishes — on a freshly pushed
                // route that ticker can stall before its first tick,
                // leaving fully-loaded tiles invisible until some
                // later interaction nudges the rendering pipeline
                // (the "map only shows up after I tap it" symptom).
                // Instantaneous display shows each tile the moment it
                // decodes, with no ticker involved.
                tileDisplay: const TileDisplay.instantaneous(),
              ),
              MarkerLayer(
                markers: [
                  for (final m in members)
                    Marker(
                      // Width fits ~5–6 CJK chars or 8 Latin chars; the
                      // inner `Container` clamps with `maxLines: 1 +
                      // ellipsis` so longer names look truncated rather
                      // than wrapping. The old 44 px width was too
                      // narrow for 4-character Chinese names — the
                      // BUGS_TO_FIX user complaint of "人名没有完全显示出来".
                      width: 130,
                      height: 80,
                      point: LatLng(m.lat, m.lng),
                      alignment: Alignment.topCenter,
                      child: _MemberMarker(member: m),
                    ),
                ],
              ),
              // OSM tile usage policy requires visible attribution.
              // Keep it small and on a translucent background so it
              // doesn't fight with markers.
              const Positioned(left: 0, bottom: 0, child: _OsmAttribution()),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberMarker extends StatelessWidget {
  final MemberLocation member;
  const _MemberMarker({required this.member});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarColorFor(member.userId);
    return SizedBox(
      width: 130,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name badge — sits above the avatar pin so the full
          // username is visible even on 4-char CJK names
          // ("王小明", "张美玲"). White pill with a 1px outline in
          // the member's avatar color so the badge and pin read as
          // one marker, not two.
          Container(
            constraints: const BoxConstraints(maxWidth: 124),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              member.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AvatarWidget(
              label: memberAvatarLabel(member.username),
              color: color,
              imageUrl: member.userAvatarUrl,
              radius: 16,
            ),
          ),
          // Small triangle pointing down (pin tail).
          Container(width: 2, height: 6, color: color),
        ],
      ),
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: Colors.white70,
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final FamilyLocations data;
  final AppLocalizations l10n;
  const _StatsStrip({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.locationOnlineCount(
                data.onlineMemberCount,
                data.totalMemberCount,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            l10n.locationTotalMembers(data.totalMemberCount),
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// Shows a permission / GPS-off banner based on the LocationProvider's
/// current status. Hidden entirely when the provider is happy.
class _ProviderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = context.watch<LocationProvider>().status;
    switch (status) {
      case LocationStatus.running:
      case LocationStatus.idle:
      case LocationStatus.error:
        return const SizedBox.shrink();
      case LocationStatus.permissionDenied:
        return _Banner(
          color: AppColors.warning,
          icon: Icons.location_off_outlined,
          message: l10n.locationPermissionBody,
          action: TextButton(
            onPressed: () =>
                context.read<LocationProvider>().reportNow().then((_) {
                  // The OS dialog handles the actual grant; this just
                  // re-tries after the user comes back.
                }),
            child: Text(l10n.locationPermissionGrant),
          ),
        );
      case LocationStatus.permissionPermanentlyDenied:
        return _Banner(
          color: AppColors.danger,
          icon: Icons.location_disabled,
          message: l10n.locationPermissionDenied,
          action: TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: Text(l10n.locationPermissionOpenSettings),
          ),
        );
      case LocationStatus.gpsOff:
        return _Banner(
          color: AppColors.warning,
          icon: Icons.gps_off,
          message: l10n.locationGpsOff,
          action: null,
        );
    }
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  final Widget? action;

  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 12, color: color)),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final int total;
  const _EmptyState({required this.l10n, required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching,
              size: 56,
              color: AppColors.primaryLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.locationNoData,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.locationNoDataDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            if (total > 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.locationTotalMembers(total),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reverse-geocoded address for one member. Reads from
/// [AddressResolver] which already coalesces concurrent calls and
/// caches by (coord, locale), so the Future below resolves fast
/// after the first build.
class _AddressLine extends StatelessWidget {
  final double lng;
  final double lat;
  final Locale locale;
  final AppLocalizations l10n;
  const _AddressLine({
    required this.lng,
    required this.lat,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AddressResolver.resolve(lng, lat, locale),
      initialData: AddressResolver.peek(lng, lat, locale),
      builder: (context, snap) {
        // Check `hasData` before `connectionState` so a cache hit
        // (delivered via `initialData`) renders the address
        // immediately instead of flashing the loading spinner for the
        // one microtask `resolve` always takes, even on a cache hit.
        if (snap.hasData) {
          return Text(
            snap.data!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.locationResolving,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          );
        }
        return Text(
          l10n.locationAddressUnavailable,
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final MemberLocation member;
  final AppLocalizations l10n;
  const _MemberTile({required this.member, required this.l10n});

  String _batteryLabel() {
    if (member.battery < 0) return l10n.locationBatteryUnknown;
    return l10n.locationBattery(member.battery);
  }

  String _timeLabel() {
    if (member.minutesAgo == 0) return l10n.locationUpdatedJustNow;
    return l10n.locationUpdatedMinutesAgo(member.minutesAgo);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarColorFor(member.userId);
    final locale = Localizations.localeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AvatarWidget(
            label: memberAvatarLabel(member.username),
            color: color,
            imageUrl: member.userAvatarUrl,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.username,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: member.isFresh
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.textHint.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        member.isFresh
                            ? l10n.locationOnline
                            : l10n.locationOffline,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: member.isFresh
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Address line replaces the old "lng, lat" string per
                // BUGS_TO_FIX user requirement. The widget rebuilds
                // when notifyListeners() fires (location toggle,
                // status changes) but `FutureBuilder` keyed by the
                // (lng, lat, locale) tuple effectively memoizes via
                // AddressResolver's internal cache, so the platform
                // geocoder is hit exactly once per (member, locale).
                _AddressLine(
                  lng: member.lng,
                  lat: member.lat,
                  locale: locale,
                  l10n: l10n,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.battery_full,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _batteryLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _timeLabel(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// On/off toggle for the §6.1 background location-sharing loop.
/// ON → `_provider.startSharing()` (1-minute timer + immediate
/// first sample, plus a "last gasp" sample on `AppLifecycleState.paused`).
/// OFF → `_provider.stopSharing()` (timer cancelled, lifecycle
/// observer detached, no more network).
///
/// While a GPS acquire is in flight (`isAttempting == true`) we
/// disable the switch to avoid an orphaned in-flight future —
/// toggling off mid-sample would leave `_captureFix` running with
/// no consumer for its result. The `Switch`'s onChanged is left
/// enabled when the sample fails — only the *toggling* is
/// blocked, not the next sample after it resolves.
class _ShareToggle extends StatelessWidget {
  final VoidCallback onChanged;
  const _ShareToggle({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<LocationProvider>();
    final isRunning = provider.isRunning;
    final isAttempting = provider.isAttempting;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRunning ? AppColors.primary : AppColors.divider,
          width: isRunning ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isRunning
                  ? AppColors.primaryLight.withValues(alpha: 0.25)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAttempting
                  ? Icons.gps_not_fixed
                  : (isRunning ? Icons.location_on : Icons.location_off),
              color: isRunning ? AppColors.primary : AppColors.textHint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRunning
                      ? l10n.locationShareOnTitle
                      : l10n.locationShareOffTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isAttempting
                      ? l10n.locationLocating
                      : (isRunning
                            ? l10n.locationShareOnSubtitle
                            : l10n.locationShareOffSubtitle),
                  style: TextStyle(
                    fontSize: 12,
                    color: isAttempting
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: isRunning,
            // `onChanged: null` when a sample is in flight → renders
            // the switch grey (Material's standard disabled look)
            // but keeps the row visible so the user sees the
            // "Locating…" subtitle rather than a row that just
            // disappears.
            onChanged: isAttempting ? null : (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

/// Tiny status line above the "Share my location" button that
/// surfaces the local user's own upload state. Without this, the
/// §6.1 background loop is invisible — the user can't tell whether
/// their timer is actually firing and their fix is reaching the
/// server. The line also reflects `lastError` so a permanent
/// failure (e.g. server 500) doesn't go unnoticed.
class _LastReportedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<LocationProvider>();
    final last = provider.lastReportAt;
    final error = provider.lastError;
    final IconData icon;
    final String text;
    final Color color;
    if (error != null) {
      icon = Icons.error_outline;
      // Translate the provider's machine-readable error code into a
      // localized message (no raw English bleeding into the UI).
      text = switch (error) {
        'GPS_TIMEOUT' => l10n.locationGpsTimeout,
        'GPS_NOT_AVAILABLE' => l10n.locationGpsUnavailable,
        'GPS_OFF' => l10n.locationGpsOff,
        _ => l10n.locationReportFailed,
      };
      color = AppColors.danger;
    } else if (provider.isAttempting) {
      // Don't display this branch as an error — the user explicitly
      // requested a report (or the background tick is in flight),
      // and the actual outcome will replace this line within ~30 s
      // either way. The "(attempt N)" suffix tells the user the
      // system is actively trying rather than silently stuck.
      icon = Icons.gps_not_fixed;
      text = l10n.locationLocating;
      color = AppColors.primary;
    } else if (last == null) {
      icon = Icons.cloud_upload_outlined;
      text = l10n.locationReportNow;
      color = AppColors.textHint;
    } else {
      final agoSec = DateTime.now().difference(last).inSeconds;
      final agoLabel = agoSec < 5
          ? l10n.locationUpdatedJustNow
          : agoSec < 60
          ? '${agoSec}s'
          : l10n.locationUpdatedMinutesAgo(agoSec ~/ 60);
      icon = Icons.cloud_done_outlined;
      text = agoLabel;
      color = AppColors.success;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
        if (provider.isAttempting && provider.attemptCount > 1) ...[
          const SizedBox(width: 4),
          Text(
            '(#${provider.attemptCount})',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}
