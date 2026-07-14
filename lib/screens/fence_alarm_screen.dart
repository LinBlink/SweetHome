import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/fence.dart';
import '../providers/auth_provider.dart';
import '../services/location_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';

/// §6.7 fence-alarm inbox. Lists every fence-entry / fence-exit
/// alert for fences the current user *set* (i.e. fences whose
/// notifications are routed to them — see docs/api.md §6.4 "谁
/// 设置围栏，越界后就通知谁"). Newest first.
class FenceAlarmScreen extends StatefulWidget {
  const FenceAlarmScreen({super.key});

  @override
  State<FenceAlarmScreen> createState() => _FenceAlarmScreenState();
}

class _FenceAlarmScreenState extends State<FenceAlarmScreen> {
  late LocationService _service;
  Future<List<FenceAlarm>>? _future;

  @override
  void initState() {
    super.initState();
    _service = LocationService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    _future = _load();
  }

  Future<List<FenceAlarm>> _load() {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.mockFenceAlarms());
    }
    return _service.listFenceAlarms();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.fenceAlarmsTitle)),
      body: FutureBuilder<List<FenceAlarm>>(
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
              onDismiss: _refresh,
            );
          }
          final alarms = snap.data ?? const <FenceAlarm>[];
          if (alarms.isEmpty) {
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
                          Icons.notifications_none,
                          size: 56,
                          color: AppColors.primaryLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.fenceAlarmEmpty,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.fenceAlarmEmptyDesc,
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
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: alarms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _AlarmCard(alarm: alarms[i], l10n: l10n),
            ),
          );
        },
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final FenceAlarm alarm;
  final AppLocalizations l10n;
  const _AlarmCard({required this.alarm, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isInside = alarm.isInside;
    final color = isInside ? AppColors.success : AppColors.danger;
    final icon = isInside ? Icons.login : Icons.logout;
    final typeLabel = isInside ? l10n.fenceAlarmInside : l10n.fenceAlarmOutside;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                          alarm.targetUsername,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          alarm.fenceName ?? l10n.fenceListTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        l10n.fenceAlarmTime(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(alarm.alarmedAt.toLocal()),
                        ),
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
            const SizedBox(width: 8),
            AvatarWidget(
              label: memberAvatarLabel(alarm.targetUsername),
              color: AppColors.avatarColorFor(alarm.targetUserId),
              imageUrl: alarm.targetUserAvatarUrl,
              radius: 18,
            ),
          ],
        ),
      ),
    );
  }
}