import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/time/app_time_formatter.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../models/fence.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';
import 'fence_create_screen.dart';

/// §6.6 fence list — "what geofences has this family set, and where".
/// Anyone in the family can see every fence (not just the ones they
/// themselves set), but only the original setter can delete their own
/// (server-enforced; the delete UI is gated on `setterUserId ==
/// currentUserId`).
class FenceListScreen extends StatefulWidget {
  const FenceListScreen({super.key});

  @override
  State<FenceListScreen> createState() => _FenceListScreenState();
}

class _FenceListScreenState extends State<FenceListScreen> {
  late LocationService _service;
  Future<List<Fence>>? _future;

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _future = _load();
  }

  Future<List<Fence>> _load() {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.mockFences());
    }
    return _service.listFences();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _delete(Fence fence) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.fenceDeleteConfirm,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.fenceDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (AppConfig.mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      } else {
        await _service.deleteFence(fence.id);
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.fenceDeleteSuccess)));
      await _refresh();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(e.message, l10n))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))),
      );
    }
  }

  Future<List<FamilyMemberVm>> _loadMembers() async {
    return context.read<AuthProvider>().loadFamilyMembers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.fenceListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FenceCreateScreen()),
          );
          if (mounted) await _refresh();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.fenceCreateButton),
      ),
      body: FutureBuilder<List<Fence>>(
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
              onDismiss: _refresh,
            );
          }
          final fences = snap.data ?? const <Fence>[];
          final me = context.watch<AuthProvider>().currentUser?.userId;
          if (fences.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 56,
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.fenceListEmpty,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.fenceListEmptyDesc,
                          textAlign: TextAlign.center,
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
          // Split per the viewer's relationship to each fence — the
          // same fence list reads very differently from each side:
          // the setters see "where I'm watching", the targets see
          // "who's watching me". A fence where `me == setter ==
          // target` (the rare self-fence case) lands in the "I'm
          // watching" group since that's the more useful bucket
          // (the user can still delete it from there).
          final guarding =
              fences.where((f) => me != null && f.setterUserId == me).toList();
          final guarded =
              fences.where((f) => me != null && f.targetUserId == me).toList();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _FenceGroupSection(
                  title: l10n.fenceListGuardingGroup,
                  fences: guarding,
                  emptyHint: l10n.fenceListNoGuarding,
                  emptyIcon: Icons.add_location_alt_outlined,
                  onDelete: _delete,
                  membersLoader: _loadMembers,
                ),
                const SizedBox(height: 18),
                _FenceGroupSection(
                  title: l10n.fenceListGuardedGroup,
                  fences: guarded,
                  emptyHint: l10n.fenceListNoGuarded,
                  emptyIcon: Icons.location_searching,
                  onDelete: _delete,
                  membersLoader: _loadMembers,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Renders one of the two fence-list groups ("I'm watching" /
/// "Watching me") with a section header, the cards stacked
/// top-to-bottom inside, or a small empty hint when the group has
/// no fences. Empty and non-empty groups both render — hiding the
/// group entirely when empty would make a brand-new user think the
/// feature is broken ("I never set any up, so where's the screen
/// for it?"); the explicit hint reassures them that the bucket
/// exists, just nothing's in it yet.
class _FenceGroupSection extends StatelessWidget {
  final String title;
  final List<Fence> fences;
  final String emptyHint;
  final IconData emptyIcon;
  final Future<void> Function(Fence) onDelete;
  final Future<List<FamilyMemberVm>> Function() membersLoader;

  const _FenceGroupSection({
    required this.title,
    required this.fences,
    required this.emptyHint,
    required this.emptyIcon,
    required this.onDelete,
    required this.membersLoader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${fences.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (fences.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(
                  emptyIcon,
                  size: 18,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    emptyHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final f in fences) ...[
            _FenceCard(
              fence: f,
              onDelete: () => onDelete(f),
              membersLoader: membersLoader,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _FenceCard extends StatelessWidget {
  final Fence fence;
  final VoidCallback onDelete;
  final Future<List<FamilyMemberVm>> Function() membersLoader;
  const _FenceCard({
    required this.fence,
    required this.onDelete,
    required this.membersLoader,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final me = context.watch<AuthProvider>().currentUser;
    final isMine = me != null && me.userId == fence.setterUserId;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fence.name ?? l10n.fenceListTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMine)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                    onPressed: onDelete,
                    tooltip: l10n.fenceDelete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  l10n.fenceRadiusLabel(fence.fenceRange.round()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(fence.fenceLat, fence.fenceLng),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'asia.sweethome.flutter',
                      maxZoom: 19,
                      tileDisplay: const TileDisplay.instantaneous(),
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(fence.fenceLat, fence.fenceLng),
                          radius: fence.fenceRange,
                          useRadiusInMeter: true,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<FamilyMemberVm>>(
              future: membersLoader(),
              builder: (_, snap) {
                final members = snap.data ?? const <FamilyMemberVm>[];
                FamilyMemberVm? setter;
                FamilyMemberVm? target;
                for (final m in members) {
                  if (m.userId == fence.setterUserId) setter = m;
                  if (m.userId == fence.targetUserId) target = m;
                }
                final createdStr = AppTimeFormatter(Localizations.localeOf(context))
                    .forRecordList(fence.createdAt.toLocal());
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (target != null)
                      _MemberLine(
                        icon: Icons.visibility_outlined,
                        label: '${l10n.fenceTargetLabel}:',
                        member: target,
                      ),
                    if (setter != null)
                      _MemberLine(
                        icon: Icons.settings_outlined,
                        label: '${l10n.fenceCreatedBy}:',
                        member: setter,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          l10n.fenceCreatedAt(createdStr),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final FamilyMemberVm member;
  const _MemberLine({
    required this.icon,
    required this.label,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textHint),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(width: 6),
          AvatarWidget(
            label: memberAvatarLabel(member.name),
            color: AppColors.avatarColorFor(member.userId),
            imageUrl: member.avatarUrl,
            radius: 10,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              member.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}