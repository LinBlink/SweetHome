import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/address_resolver.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/time/app_time_formatter.dart';
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

class _LocationHistoryScreenState extends State<LocationHistoryScreen>
    with TickerProviderStateMixin {
  late LocationService _service;
  late FamilyMemberVm? _member;
  DateTime _date = DateTime.now();
  Future<LocationHistory>? _future;
  final MapController _mapController = MapController();

  /// Playback head. Drives which point is highlighted by the
  /// extra marker on the map. Always 0 before the first playback
  /// so the slider sits at the start of the trail.
  AnimationController? _player;
  int _currentIndex = 0;

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
    _player?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Build (or rebuild) the playback controller for the given
  /// points. Total duration scales with point count so even a
  /// 50-point trail still finishes in 8-ish seconds at 150 ms/
  /// frame, and a 5-point trail still plays in ~1 second instead
  /// of sliding several seconds between frames.
  void _ensurePlayer(int pointCount) {
    if (pointCount <= 1) {
      _player?.dispose();
      _player = null;
      return;
    }
    final target = Duration(milliseconds: (pointCount - 1) * 150);
    final existing = _player;
    if (existing != null && existing.duration == target) {
      return;
    }
    existing?.dispose();
    _player = AnimationController(vsync: this, duration: target)
      ..addListener(() {
        if (!mounted) return;
        // (controller.value, 0..1) → (currentIndex, 0..pointCount-1).
        final v = _player!.value.clamp(0.0, 1.0);
        final max = pointCount - 1;
        setState(() {
          _currentIndex = (v * max).round();
        });
      });
  }

  void _togglePlayback(int pointCount) {
    final p = _player;
    if (p == null) return;
    if (p.isAnimating) {
      p.stop();
      setState(() {}); // refresh icon state
      return;
    }
    // End-of-trail → rewind to the start so "Replay" works.
    if ((p.value >= 1.0) || _currentIndex >= pointCount - 1) {
      _currentIndex = 0;
      p.value = 0.0;
    }
    p.forward();
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
                    style: TextStyle(
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
                  return Center(
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
                // Build (or rebuild) the playback controller for the
                // current point count. Must run in build (not in
                // didUpdateWidget) because [setState] here keeps the
                // player sized to the new day after a date pick.
                _ensurePlayer(data.locations.length);
                final locale = Localizations.localeOf(context);
                final playbackActive = _player?.isAnimating ?? false;
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
                                    child: _EndpointDot(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  // Playback head — only shown when the
                                  // trail has enough points to be worth
                                  // animating. Sits on top of the endpoint
                                  // markers; we don't hide the endpoints
                                  // because they carry the meaning of
                                  // "where the day started / ended", which
                                  // the playback dot doesn't.
                                  if (_player != null)
                                    Marker(
                                      width: 28,
                                      height: 28,
                                      point: LatLng(
                                        data.locations[_currentIndex].lat,
                                        data.locations[_currentIndex].lng,
                                      ),
                                      child: const _PlaybackDot(),
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
                    if (_player != null)
                      _PlaybackStrip(
                        controller: _player!,
                        currentIndex: _currentIndex,
                        maxIndex: data.locations.length - 1,
                        isPlaying: playbackActive,
                        onToggle: () => _togglePlayback(data.locations.length),
                        l10n: l10n,
                      ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppColors.surface,
                      child: Text(
                        l10n.locationHistoryPointCount(data.locations.length),
                        style: TextStyle(
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
                          locale: locale,
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
            Icon(Icons.history, size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              l10n.locationHistoryTitle,
              style: TextStyle(
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.locationHistoryEmptyDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 14),
            Text(
              AppTimeFormatter(Localizations.localeOf(context))
                  .forDateOnly(date),
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
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
  final Locale locale;
  final AppLocalizations l10n;
  const _HistoryTile({
    required this.point,
    required this.isFirst,
    required this.isLast,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final time = AppTimeFormatter(locale).forTimeOnly(point.updatedAt.toLocal());
    // Address line is rendered only for the first and last points
    // (the endpoints the user is most likely to want to identify
    // — "where did the day start?", "where did they end up?").
    // Internal points rely on the polyline + endpoint markers.
    final showAddress = isFirst || isLast;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (point.battery >= 0)
                      Text(
                        l10n.locationHistoryBatteryLabel(point.battery),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
                if (showAddress) ...[
                  const SizedBox(height: 4),
                  _PointAddressLine(
                    lng: point.lng,
                    lat: point.lat,
                    locale: locale,
                    l10n: l10n,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reverse-geocoded single-line address for a trajectory point.
/// Reuses [AddressResolver] (same as `_AddressLine` in
/// `LocationScreen`) so the cache, in-flight dedup, and locale
/// fallback all apply here too — visiting the live map first
/// typically pre-warms the cache for the start/end of the trail.
class _PointAddressLine extends StatelessWidget {
  final double lng;
  final double lat;
  final Locale locale;
  final AppLocalizations l10n;
  const _PointAddressLine({
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
        if (snap.hasData) {
          return Text(
            l10n.locationHistoryPointAddress(snap.data!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
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
                style:
                    TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          );
        }
        return Text(
          l10n.locationAddressUnavailable,
          style: TextStyle(fontSize: 12, color: AppColors.textHint),
        );
      },
    );
  }
}

/// Play / pause control + scrubber for the trajectory. Bound to
/// the same `AnimationController` that drives the playback-dot
/// marker on the map — dragging the slider also moves the head.
class _PlaybackStrip extends StatelessWidget {
  final AnimationController controller;
  final int currentIndex;
  final int maxIndex;
  final bool isPlaying;
  final VoidCallback onToggle;
  final AppLocalizations l10n;
  const _PlaybackStrip({
    required this.controller,
    required this.currentIndex,
    required this.maxIndex,
    required this.isPlaying,
    required this.onToggle,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final atEnd = currentIndex >= maxIndex;
    final iconLabel = !isPlaying && atEnd
        ? l10n.locationHistoryReplay
        : (isPlaying ? l10n.locationHistoryPause : l10n.locationHistoryPlay);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggle,
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : (atEnd ? Icons.replay_rounded : Icons.play_arrow_rounded),
                  color: AppColors.primary,
                  size: 24,
                  semanticLabel: iconLabel,
                ),
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceVariant,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.15),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: controller.value.clamp(0.0, 1.0),
                onChanged: (v) {
                  controller.value = v;
                  controller.stop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The playback head marker on the map. Distinct shape from
/// the static endpoint dots so it reads as "moving" at a glance.
class _PlaybackDot extends StatelessWidget {
  const _PlaybackDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
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
      child: Text(
        '© OpenStreetMap contributors',
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }
}