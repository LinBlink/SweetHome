import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';

/// §6.4 fence creation screen. Two inputs the user has to provide:
///   1. Which family member is being watched (target).
///   2. Where on the map the fence center is + what its radius is.
///
/// The map is a single-tap picker: tapping the map drops a marker
/// at the tapped (lng, lat), and a slider controls the radius. The
/// "Create" button is enabled only when both target and center are
/// set and the radius is > 0 (server validates the radius > 0 too,
/// but it's friendlier to gate the button client-side).
class FenceCreateScreen extends StatefulWidget {
  const FenceCreateScreen({super.key});

  @override
  State<FenceCreateScreen> createState() => _FenceCreateScreenState();
}

class _FenceCreateScreenState extends State<FenceCreateScreen> {
  late LocationService _locationService;
  final _nameCtrl = TextEditingController();
  final _mapController = MapController();
  FamilyMemberVm? _target;
  LatLng? _center;
  double _radiusMeters = 200;
  bool _saving = false;
  String? _error;
  Future<List<FamilyMemberVm>>? _membersFuture;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _membersFuture = _loadMembers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<List<FamilyMemberVm>> _loadMembers() async {
    return context.read<AuthProvider>().loadFamilyMembers();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (_target == null) {
      setState(() => _error = l10n.fenceTargetLabel);
      return;
    }
    if (_center == null) {
      setState(() => _error = l10n.fencePickLocationRequired);
      return;
    }
    if (_radiusMeters <= 0) {
      setState(() => _error = l10n.fenceInvalidRange);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (AppConfig.mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        await _locationService.createFence(
          targetUserId: _target!.userId,
          fenceLng: _center!.longitude,
          fenceLat: _center!.latitude,
          rangeMeters: _radiusMeters,
          name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        );
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.fenceCreateSuccess)));
      navigator.pop();
    } on ApiException catch (e) {
      setState(() => _error = localizeErrorMessage(e.message, l10n));
    } catch (_) {
      setState(() => _error = localizeErrorMessage(kNetworkErrorSentinel, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.fenceCreateTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(l10n),
            child: Text(
              l10n.fenceCreateButton,
              style: TextStyle(
                color: _saving ? AppColors.textHint : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<FamilyMemberVm>>(
              future: _membersFuture,
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
                      _membersFuture = _loadMembers();
                    }),
                  );
                }
                final members =
                    (snap.data ?? const <FamilyMemberVm>[]).toList();
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 12),
                    _SectionLabel(text: l10n.fenceTargetLabel),
                    const SizedBox(height: 8),
                    if (members.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          l10n.fenceNoWatchableMembers,
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in members)
                            _MemberChip(
                              member: m,
                              selected: _target?.userId == m.userId,
                              onTap: () => setState(() => _target = m),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _SectionLabel(text: l10n.fenceNameLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: l10n.fenceNameHint,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel(text: l10n.fencePickLocationTitle),
                    const SizedBox(height: 6),
                    Text(
                      _center == null
                          ? l10n.fencePickLocationHint
                          : l10n.fencePickLocationSelected,
                      style: TextStyle(
                        fontSize: 12,
                        color: _center == null
                            ? AppColors.textHint
                            : AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MapPicker(
                      mapController: _mapController,
                      center: _center,
                      radiusMeters: _radiusMeters,
                      onTap: (ll) => setState(() => _center = ll),
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel(text: l10n.fenceRangeLabel),
                    Slider(
                      min: 50,
                      max: 2000,
                      divisions: 39,
                      value: _radiusMeters,
                      label: '${_radiusMeters.round()} m',
                      onChanged: (v) => setState(() => _radiusMeters = v),
                    ),
                    Center(
                      child: Text(
                        l10n.fenceRadiusLabel(_radiusMeters.round()),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final FamilyMemberVm member;
  final bool selected;
  final VoidCallback onTap;
  const _MemberChip({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(
              label: memberAvatarLabel(member.name),
              color: selected
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.avatarColorFor(member.userId),
              imageUrl: member.avatarUrl,
              radius: 12,
            ),
            const SizedBox(width: 6),
            Text(
              member.name,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPicker extends StatelessWidget {
  final MapController mapController;
  final LatLng? center;
  final double radiusMeters;
  final ValueChanged<LatLng> onTap;
  const _MapPicker({
    required this.mapController,
    required this.center,
    required this.radiusMeters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center ?? const LatLng(39.9087, 116.3975),
          initialZoom: 12,
          minZoom: 3,
          maxZoom: 18,
          onTap: (_, ll) => onTap(ll),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'asia.sweethome.flutter',
            maxZoom: 19,
            tileDisplay: const TileDisplay.instantaneous(),
          ),
          if (center != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center!,
                  radius: radiusMeters,
                  useRadiusInMeter: true,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderColor: AppColors.primary,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (center != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: center!,
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}