import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
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
  late final LocationProvider _provider;
  Future<FamilyLocations>? _future;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _provider = LocationProvider(
      service: _service,
      mockMode: AppConfig.mockMode,
    );
    // Kick off the upload loop as soon as the screen is on stage —
    // the spec says "首次采集必定上报" so the first sample goes
    // out before the user even sees the map.
    _provider.startSharing();
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
    _provider.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadLocations());
    await _future;
  }

  Future<void> _shareMyLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _provider.reportNow();
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.locationReportNow)));
      _refresh();
    } else {
      // Translate the provider's machine-readable error code into a
      // localized message. Unknown codes fall back to the generic
      // "could not share location" so the user at least knows the
      // button didn't work.
      final err = _provider.lastError;
      final localized = switch (err) {
        'GPS_TIMEOUT' => l10n.locationGpsTimeout,
        'GPS_NOT_AVAILABLE' => l10n.locationGpsUnavailable,
        'GPS_OFF' => l10n.locationGpsOff,
        _ => l10n.locationReportFailed,
      };
      messenger.showSnackBar(SnackBar(content: Text(localized)));
    }
  }

  /// Center the map on the cluster of member fixes. If only one
  /// member is sharing, zoom to a fixed level (15 ≈ street view).
  void _fitToMembers(List<MemberLocation> members) {
    if (members.isEmpty) return;
    if (members.length == 1) {
      _mapController.move(LatLng(members.first.lat, members.first.lng), 15);
      return;
    }
    final points = members.map((m) => LatLng(m.lat, m.lng)).toList();
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Watch the provider so the "Share my location" button reflects
    // permission/permission-permanently-denied/gps-off status.
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
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
                    builder: (_) => ChangeNotifierProvider.value(
                      value: _provider,
                      child: const LocationDebugScreen(),
                    ),
                  ),
                ),
                tooltip: 'Location debug',
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
            // Auto-fit on the first successful load (or when the
            // marker set changes from empty to non-empty).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fitToMembers(members);
            });
            return Column(
              children: [
                _MapPanel(members: members, mapController: _mapController),
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
                        _ShareLocationButton(onPressed: _shareMyLocation),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  final List<MemberLocation> members;
  final MapController mapController;

  const _MapPanel({required this.members, required this.mapController});

  @override
  Widget build(BuildContext context) {
    // Sensible default center: Beijing (天安门). When the family
    // members come back with fixes we call fitToMembers in the
    // post-frame callback above to override this.
    const initialCenter = LatLng(39.9087, 116.3975);
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: initialCenter,
              initialZoom: 11,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'asia.sweethome.flutter',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  for (final m in members)
                    Marker(
                      width: 44,
                      height: 44,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AvatarWidget(
            label: memberAvatarLabel(member.username),
            color: color,
            imageUrl: member.userAvatarUrl,
            radius: 20,
          ),
        ),
        // Small triangle pointing down (pin tail).
        Container(width: 2, height: 8, color: color),
      ],
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
            onPressed: () {
              // No platform channel for opening settings without a
              // plugin; just surface a hint. Tapping "Open settings"
              // would call `permission_handler.openAppSettings()`,
              // but adding that dep just for this is overkill —
              // the system surfaces the deep-link elsewhere.
            },
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
                Text(
                  l10n.locationCoordinates(
                    member.lng.toStringAsFixed(4),
                    member.lat.toStringAsFixed(4),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
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

/// "Share my location" button, disabled + spinning while a capture is
/// in flight. `LocationProvider.reportNow()` can take up to ~90s
/// (multi-tier GPS fallback) before it resolves either way — without
/// this the button stays tappable and visually unchanged the whole
/// time, which looks exactly like the tap did nothing until the error
/// toast finally appears (see `LocationProvider._attemptSample`'s doc
/// comment for the underlying fix: `isAttempting` used to only be
/// tracked for the background timer, not the manual button).
class _ShareLocationButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ShareLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAttempting = context.watch<LocationProvider>().isAttempting;
    return ElevatedButton.icon(
      icon: isAttempting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.my_location),
      label: Text(l10n.locationReportNow),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: isAttempting ? null : onPressed,
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
