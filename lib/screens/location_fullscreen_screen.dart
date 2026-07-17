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
import '../services/location_service.dart';
import '../widgets/avatar_widget.dart';

/// Dedicated fullscreen route for the location map. Hides the
/// AppBar, list, stats bar, share-toggle row — the entire body is
/// the OSM map with markers and the OSM attribution. A back arrow
/// in the top-left overlay pops back to the normal LocationScreen.
///
/// Push this from `LocationScreen`'s fullscreen button. The route
/// re-issues its own `GET /location/family` on first build so a
/// user who navigates in before the underlying screen's fetch
/// completed still sees the up-to-date positions.
class LocationFullscreenScreen extends StatefulWidget {
  const LocationFullscreenScreen({super.key});

  @override
  State<LocationFullscreenScreen> createState() =>
      _LocationFullscreenScreenState();
}

class _LocationFullscreenScreenState
    extends State<LocationFullscreenScreen> {
  late final LocationService _service;
  final MapController _mapController = MapController();
  Future<FamilyLocations>? _future;

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _future = _loadLocations();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<FamilyLocations> _loadLocations() {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.mockFamilyLocations());
    }
    return _service.fetchFamilyLocations();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadLocations());
    await _future;
  }

  void _fitToMembers(List<MemberLocation> members) {
    if (members.isEmpty) return;
    if (members.length == 1) {
      _mapController.move(LatLng(members.first.lat, members.first.lng), 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(
      members.map((m) => LatLng(m.lat, m.lng)).toList(),
    );
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Widget _buildMarker(MemberLocation m) {
    final color = AppColors.avatarColorFor(m.userId);
    return SizedBox(
      width: 130,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              m.username,
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
              label: memberAvatarLabel(m.username),
              color: color,
              imageUrl: m.userAvatarUrl,
              radius: 16,
            ),
          ),
          Container(width: 2, height: 6, color: color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FutureBuilder<FamilyLocations>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snapshot.hasError) {
                final isApi = snapshot.error is ApiException;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      localizeErrorMessage(
                        isApi
                            ? (snapshot.error as ApiException).message
                            : kNetworkErrorSentinel,
                        l10n,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final members = snapshot.data!.familyMemberLocations;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _fitToMembers(members);
              });
              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(39.9087, 116.3975),
                  initialZoom: 11,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'asia.sweethome.flutter',
                    maxZoom: 19,
                    // See the same option in LocationScreen's
                    // TileLayer for why: default fade-in relies on a
                    // ticker that can stall on a freshly pushed
                    // route, leaving loaded tiles invisible until an
                    // interaction happens to nudge a repaint.
                    tileDisplay: const TileDisplay.instantaneous(),
                  ),
                  MarkerLayer(
                    markers: [
                      for (final m in members)
                        Marker(
                          width: 130,
                          height: 80,
                          point: LatLng(m.lat, m.lng),
                          alignment: Alignment.topCenter,
                          child: _buildMarker(m),
                        ),
                    ],
                  ),
                  const Positioned(
                    left: 0,
                    bottom: 0,
                    child: _AttrBadge(),
                  ),
                ],
              );
            },
          ),
          // Top-left back arrow.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.textPrimary,
                  tooltip: l10n.locationExitFullscreen,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          // Top-right refresh.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: const Icon(Icons.refresh),
                    color: AppColors.textPrimary,
                    tooltip: l10n.locationRefresh,
                    onPressed: _refresh,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttrBadge extends StatelessWidget {
  const _AttrBadge();

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