import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../models/location.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';

/// §6.3 trajectory history viewer. Push from a location-screen member
/// tile or a family-members tile. Shows the member's full day's
/// location history as a polyline on the map, with a date picker to
/// pick a different day. Empty / single-point histories render an
/// informative empty state instead of a degenerate "line of 1".
class LocationHistoryScreen extends StatefulWidget {
  /// Family member to inspect. Null when called from screens that
  /// don't already have the member in hand — the screen will then
  /// prompt the user to pick one from the family list.
  final FamilyMemberVm? member;
  const LocationHistoryScreen({super.key, this.member});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  late LocationService _service;
  late FamilyMemberVm? _member;
  DateTime _date = DateTime.now();
  Future<LocationHistory>? _future;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _member = widget.member;
    if (_member != null) {
      _future = _fetch(_member!.userId, _date);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<LocationHistory> _fetch(int userId, DateTime date) {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.mockLocationHistory(targetUserId: userId));
    }
    return _service.fetchLocationHistory(targetUserId: userId, date: date);
  }

  Future<void> _pickMember() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    List<FamilyMemberVm> members;
    try {
      members = await context.read<AuthProvider>().loadFamilyMembers();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(e.message, l10n))),
      );
      return;
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))),
      );
      return;
    }
    if (!mounted) return;
    // Show every family member, including the viewer themselves —
    // an earlier version filtered out `me`, which silently
    // disallowed "查看自己的轨迹" (reviewing where I went today).
    final auth = context.read<AuthProvider>();
    final me = auth.currentUser?.userId;
    final ordered = [...members]..sort((a, b) {
        // Self floats to the top so picking "我的轨迹" is one tap,
        // not a scroll — everyone else's list keeps its server
        // order.
        if (a.userId == me) return -1;
        if (b.userId == me) return 1;
        return 0;
      });
    if (ordered.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.locationHistoryEmptyDesc)),
      );
      return;
    }
    final picked = await showModalBottomSheet<FamilyMemberVm>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: ordered.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
          itemBuilder: (_, i) => ListTile(
            leading: AvatarWidget(
              label: memberAvatarLabel(ordered[i].name),
              color: AppColors.avatarColorFor(ordered[i].userId),
              imageUrl: ordered[i].avatarUrl,
              radius: 22,
            ),
            title: Text(ordered[i].name),
            trailing: ordered[i].userId == me
                ? Text(
                    l10n.profileMe,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  )
                : null,
            onTap: () => Navigator.pop(ctx, ordered[i]),
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _member = picked;
      _future = _fetch(picked.userId, _date);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      if (_member != null) {
        _future = _fetch(_member!.userId, _date);
      }
    });
  }

  /// Same reasoning as `_initialOptions` in [LocationScreen]:
  /// setting `initialCameraFit` keeps the trajectory's first frame
  /// correct instead of relying on a post-frame `fitCamera`
  /// callback, which races the TileLayer with the PolylineLayer
  /// overlay on the first paint and on Web leaves the map blank
  /// with the polyline visible until the user drags.
  MapOptions _initialOptions(List<LocationHistoryPoint> pts) {
    if (pts.isEmpty) {
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
    if (pts.length == 1) {
      return MapOptions(
        initialCenter: LatLng(pts.first.lat, pts.first.lng),
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      );
    }
    final bounds = LatLngBounds.fromPoints(
      pts.map((p) => LatLng(p.lat, p.lng)).toList(),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _member != null
              ? l10n.locationHistoryForMember(_member!.name)
              : l10n.locationHistoryTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: l10n.locationHistoryPickDate,
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _member == null
          ? _PickMemberPrompt(onTap: _pickMember, l10n: l10n)
          : FutureBuilder<LocationHistory>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snap.hasError) {
                  final isApi = snap.error is ApiException;
                  return ErrorBanner(
                    message: localizeErrorMessage(
                      isApi
                          ? (snap.error as ApiException).message
                          : kNetworkErrorSentinel,
                      l10n,
                    ),
                    onDismiss: () => setState(() {
                      _future = _fetch(_member!.userId, _date);
                    }),
                  );
                }
                final data = snap.data!;
                if (data.isEmpty) {
                  return _EmptyState(
                    l10n: l10n,
                    onPickDate: _pickDate,
                    date: _date,
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 280,
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: _initialOptions(data.locations),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'asia.sweethome.flutter',
                                maxZoom: 19,
                                tileDisplay: const TileDisplay.instantaneous(),
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: data.locations
                                        .map((p) => LatLng(p.lat, p.lng))
                                        .toList(),
                                    strokeWidth: 4,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 36,
                                    height: 36,
                                    point: LatLng(
                                      data.locations.first.lat,
                                      data.locations.first.lng,
                                    ),
                                    child: const _EndpointDot(
                                      color: AppColors.success,
                                    ),
                                  ),
                                  Marker(
                                    width: 36,
                                    height: 36,
                                    point: LatLng(
                                      data.locations.last.lat,
                                      data.locations.last.lng,
                                    ),
                                    child: const _EndpointDot(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const Positioned(
                                left: 0,
                                bottom: 0,
                                child: _OsmAttribution(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppColors.surface,
                      child: Text(
                        l10n.locationHistoryPointCount(data.locations.length),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: data.locations.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 70),
                        itemBuilder: (_, i) => _HistoryTile(
                          point: data.locations[i],
                          isFirst: i == 0,
                          isLast: i == data.locations.length - 1,
                          l10n: l10n,
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

class _PickMemberPrompt extends StatelessWidget {
  final VoidCallback onTap;
  final AppLocalizations l10n;
  const _PickMemberPrompt({required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              l10n.locationHistoryTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.person_search),
              label: Text(l10n.locationHistoryView),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onPickDate;
  final DateTime date;
  const _EmptyState({
    required this.l10n,
    required this.onPickDate,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 56,
              color: AppColors.primaryLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.locationHistoryEmpty,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.locationHistoryEmptyDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 14),
            Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(l10n.locationHistoryPickDate),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final LocationHistoryPoint point;
  final bool isFirst;
  final bool isLast;
  final AppLocalizations l10n;
  const _HistoryTile({
    required this.point,
    required this.isFirst,
    required this.isLast,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(point.updatedAt.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Timeline dot — color hints at start/end of trail.
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFirst
                  ? AppColors.success
                  : (isLast ? AppColors.primary : AppColors.surfaceVariant),
              border: Border.all(
                color: AppColors.primary,
                width: isFirst || isLast ? 2 : 0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (point.battery >= 0)
                  Text(
                    l10n.locationHistoryBatteryLabel(point.battery),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointDot extends StatelessWidget {
  final Color color;
  const _EndpointDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
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