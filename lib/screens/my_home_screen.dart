import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/family_service.dart';
import 'join_requests_screen.dart';
import 'location_screen.dart';

/// "我的家" tab — the central feature hub from the bottom nav. Each
/// tile here is a self-contained "过家家" sub-app (real-time location,
/// join-request approvals, future additions). The hub itself is
/// stateless aside from the join-requests badge count, which is
/// loaded lazily and re-fetches when the user pulls down.
class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  Future<int>? _pendingCount;

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  /// Re-fetch the join-requests count when the user pulls to refresh.
  /// Also called from initState. We use a Future directly (not a stream)
  /// because the API has no push channel for new requests yet — the
  /// admin taps refresh or pulls to see new ones. Will be wired to the
  /// WS push later if the backend adds one.
  Future<void> _refreshPending() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    setState(() {
      _pendingCount = _fetchPendingCount(user.familyId);
    });
    await _pendingCount;
  }

  Future<int> _fetchPendingCount(int familyId) async {
    if (AppConfig.mockMode) {
      return MockDataSource.mockJoinRequests().length;
    }
    try {
      // FamilyService is an instance class (it carries the current
      // auth token); get one off AuthProvider rather than instantiating
      // a fresh, unauthenticated one.
      final familyService = FamilyService(() {
        final user = context.read<AuthProvider>().currentUser;
        return user?.token ?? '';
      });
      final list = await familyService.fetchJoinRequests(familyId);
      return list.length;
    } catch (_) {
      // Don't surface errors as a red screen on the home tab — a
      // transient network blip just means the badge shows nothing.
      // Tapping into JoinRequests still works (its own error UI runs
      // there).
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = context.watch<AuthProvider>().currentUser?.role == 'admin';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.myHomeTitle)),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshPending,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _HubTile(
              icon: Icons.location_on_outlined,
              title: l10n.myHomeLocationEntry,
              subtitle: l10n.myHomeLocationDesc,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationScreen()),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              _HubTile(
                icon: Icons.group_add_outlined,
                title: l10n.myHomeJoinRequestsEntry,
                subtitle: l10n.myHomeJoinRequestsDesc,
                badge: _pendingCount == null
                    ? null
                    : FutureBuilder<int>(
                        future: _pendingCount,
                        builder: (_, snap) {
                          final n = snap.data ?? 0;
                          if (n == 0) return const SizedBox.shrink();
                          return _PendingBadge(
                            text: l10n.myHomeJoinRequestsBadge(n),
                          );
                        },
                      ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JoinRequestsScreen(),
                    ),
                  );
                  // Refresh the badge count after the admin comes
                  // back — they may have approved/rejected some.
                  if (mounted) _refreshPending();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? badge;
  final VoidCallback onTap;

  const _HubTile({
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
      borderRadius: BorderRadius.circular(16),
      // 1 px outline so the card reads on the slightly lighter
      // background without needing a shadow that looks heavy on web.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                  ],
                ),
              ),
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

class _PendingBadge extends StatelessWidget {
  final String text;
  const _PendingBadge({required this.text});

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
