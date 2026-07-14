import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../services/location_service.dart';
import 'fence_alarm_screen.dart';
import 'fence_list_screen.dart';
import 'location_history_screen.dart';
import 'location_screen.dart';

/// Sub-app landing for "Real-time Location" — the single MyHome tile
/// that aggregates every §6 sub-feature (live map, trajectory
/// history, geofences, fence alarms). Tapping a row pushes the
/// feature's existing screen. The fence-alarm row carries the
/// unread count badge so the user has at-a-glance visibility into
/// pending alerts without having to backtrack to MyHome.
class LocationHubScreen extends StatefulWidget {
  const LocationHubScreen({super.key});

  @override
  State<LocationHubScreen> createState() => _LocationHubScreenState();
}

class _LocationHubScreenState extends State<LocationHubScreen> {
  late LocationService _service;
  Future<int>? _alarmCountFuture;

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _refreshAlarmCount();
  }

  Future<void> _refreshAlarmCount() async {
    setState(() {
      _alarmCountFuture = _fetchAlarmCount();
    });
    await _alarmCountFuture;
  }

  Future<int> _fetchAlarmCount() async {
    if (AppConfig.mockMode) {
      return MockDataSource.mockFenceAlarms().length;
    }
    try {
      final list = await _service.listFenceAlarms();
      return list.length;
    } catch (_) {
      // Transient blip → badge quietly hides itself rather than
      // painting a red error on a hub that's otherwise informational.
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Push the live-map screen with the app-scoped LocationProvider
    // re-provided — same pattern used by MyHomeScreen for the
    // location tile, since Navigator.push creates a sibling route
    // outside the original provider scope.
    final locationProvider = context.read<LocationProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.locationHubTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _FeatureRow(
            icon: Icons.location_on_outlined,
            title: l10n.locationTitle,
            subtitle: l10n.locationHubLiveMapDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: locationProvider,
                  child: const LocationScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: Icons.timeline_outlined,
            title: l10n.locationHistoryTitle,
            subtitle: l10n.locationHubHistoryDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LocationHistoryScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: Icons.shield_outlined,
            title: l10n.myHomeFenceEntry,
            subtitle: l10n.locationHubFenceDesc,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FenceListScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _FeatureRow(
            icon: Icons.notifications_active_outlined,
            title: l10n.myHomeFenceAlarmsEntry,
            subtitle: l10n.locationHubFenceAlarmsDesc,
            badge: _alarmCountFuture == null
                ? null
                : FutureBuilder<int>(
                    future: _alarmCountFuture,
                    builder: (_, snap) {
                      final n = snap.data ?? 0;
                      if (n == 0) return const SizedBox.shrink();
                      return _Badge(text: '$n');
                    },
                  ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FenceAlarmScreen(),
                ),
              );
              if (mounted) _refreshAlarmCount();
            },
          ),
        ],
      ),
    );
  }
}

/// One feature row inside the sub-app hub. Smaller than the
/// MyHome `_HubTile` so the four feature rows fit naturally without
/// the screen feeling like a duplicate of the parent hub.
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback onTap;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      // InkWell ripple has nowhere to paint without a Material
      // ancestor — see the equivalent note on FamilyMembersScreen.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        ?badge,
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}