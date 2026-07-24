import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../../core/error_messages.dart';
import '../../core/home_widgets.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/app_time_formatter.dart';
import '../../data/mock_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_exception.dart';
import '../../models/redpacket.dart';
import '../../providers/auth_provider.dart';
import '../../services/redpacket_service.dart';
import '../../widgets/avatar_widget.dart';
import 'redpacket_detail_screen.dart';

/// "My Redpackets" — a Sent / Received tabbed list backed by §9.5
/// (`GET /redpacket/i-sent`) and §9.6 (`GET /redpacket-grabs/i-received`).
/// Neither endpoint is paginated/sorted server-side yet, so this screen
/// sorts newest-first client-side after fetching the full list.
///
/// Tapping a row navigates to [RedpacketDetailScreen], which does the
/// live §9.2 fetch on entry.
class RedpacketRecordsScreen extends StatefulWidget {
  const RedpacketRecordsScreen({super.key});

  @override
  State<RedpacketRecordsScreen> createState() =>
      _RedpacketRecordsScreenState();
}

class _RedpacketRecordsScreenState extends State<RedpacketRecordsScreen> {
  Future<List<Redpacket>>? _sentFuture;
  Future<List<RedpacketGrab>>? _receivedFuture;

  @override
  void initState() {
    super.initState();
    _sentFuture = _fetchSent();
    _receivedFuture = _fetchReceived();
  }

  Future<List<Redpacket>> _fetchSent() {
    if (AppConfig.mockMode) {
      final userId = context.read<AuthProvider>().currentUser!.userId;
      return Future.value(MockDataSource.mockSentRedpackets(userId));
    }
    final token = context.read<AuthProvider>().currentUser!.token;
    return RedpacketService(() => token).listSent();
  }

  Future<List<RedpacketGrab>> _fetchReceived() {
    if (AppConfig.mockMode) {
      final userId = context.read<AuthProvider>().currentUser!.userId;
      return Future.value(MockDataSource.mockReceivedRedpacketGrabs(userId));
    }
    final token = context.read<AuthProvider>().currentUser!.token;
    return RedpacketService(() => token).listReceived();
  }

  Future<void> _refreshSent() async {
    final future = _fetchSent();
    setState(() => _sentFuture = future);
    await future;
  }

  Future<void> _refreshReceived() async {
    final future = _fetchReceived();
    setState(() => _receivedFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HomeAppBar(title: l10n.redpacketRecordsTitle),
        body: PaperBackground(
          child: Column(
            children: [
              _Tabs(l10n: l10n),
              Expanded(
                child: TabBarView(
                  children: [
                    _SentTab(
                      future: _sentFuture,
                      onRefresh: _refreshSent,
                      l10n: l10n,
                    ),
                    _ReceivedTab(
                      future: _receivedFuture,
                      onRefresh: _refreshReceived,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final AppLocalizations l10n;
  const _Tabs({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkFaded,
        indicatorColor: AppColors.primary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        tabs: [
          Tab(text: l10n.redpacketRecordsTabSent),
          Tab(text: l10n.redpacketRecordsTabReceived),
        ],
      ),
    );
  }
}

/// §9.5 tab — every red packet the current user has sent.
class _SentTab extends StatelessWidget {
  final Future<List<Redpacket>>? future;
  final Future<void> Function() onRefresh;
  final AppLocalizations l10n;

  const _SentTab({
    required this.future,
    required this.onRefresh,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: FutureBuilder<List<Redpacket>>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _scrollableState(
                const Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return _scrollableState(_ErrorState(
              message: localizeErrorMessage(
                snap.error is ApiException
                    ? (snap.error as ApiException).message
                    : kNetworkErrorSentinel,
                l10n,
              ),
              retryLabel: l10n.connectionErrorRetry,
              onRetry: onRefresh,
            ));
          }
          final list = snap.data ?? const <Redpacket>[];
          if (list.isEmpty) {
            return _scrollableState(_EmptyState(l10n: l10n));
          }
          final sorted = [...list]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) =>
                _SentTile(redpacket: sorted[i], l10n: l10n),
          );
        },
      ),
    );
  }
}

/// §9.6 tab — every red packet grab the current user has received.
class _ReceivedTab extends StatelessWidget {
  final Future<List<RedpacketGrab>>? future;
  final Future<void> Function() onRefresh;
  final AppLocalizations l10n;

  const _ReceivedTab({
    required this.future,
    required this.onRefresh,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: FutureBuilder<List<RedpacketGrab>>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _scrollableState(
                const Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError) {
            return _scrollableState(_ErrorState(
              message: localizeErrorMessage(
                snap.error is ApiException
                    ? (snap.error as ApiException).message
                    : kNetworkErrorSentinel,
                l10n,
              ),
              retryLabel: l10n.connectionErrorRetry,
              onRetry: onRefresh,
            ));
          }
          final list = snap.data ?? const <RedpacketGrab>[];
          if (list.isEmpty) {
            return _scrollableState(_EmptyState(l10n: l10n));
          }
          final sorted = [...list]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) => _ReceivedTile(grab: sorted[i], l10n: l10n),
          );
        },
      ),
    );
  }
}

/// Wraps a non-list state (loading/error/empty) in a scrollable so
/// [RefreshIndicator]'s pull-down gesture still registers — it needs a
/// `Scrollable` descendant to detect the overscroll that triggers it.
Widget _scrollableState(Widget child) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(height: 320, child: Center(child: child)),
    ],
  );
}

class _SentTile extends StatelessWidget {
  final Redpacket redpacket;
  final AppLocalizations l10n;

  const _SentTile({required this.redpacket, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = _statusDisplay(redpacket.status, l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HomeCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RedpacketDetailScreen(redpacketId: redpacket.id),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child:
                  Icon(Icons.redeem_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.redpacketAmountYuan(MoneyFormatter.format(redpacket.totalAmount))} · '
                    '${l10n.redpacketShareCountSuffix(redpacket.totalCount)}',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTimeFormatter(Localizations.localeOf(context))
                        .forConversationTile(
                      redpacket.createdAt.toLocal(),
                      timeJustNow: l10n.timeJustNow,
                      timeMinutesAgo: l10n.timeMinutesAgo,
                      timeYesterday: l10n.timeYesterday,
                    ),
                    style: TextStyle(fontSize: 12, color: AppColors.inkFaded),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedTile extends StatelessWidget {
  final RedpacketGrab grab;
  final AppLocalizations l10n;

  const _ReceivedTile({required this.grab, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // §9.6 fills the owner-info group (who sent it); the grabber is
    // always the caller, so `grab.username` stays null here — see
    // `RedpacketGrab`'s doc comment.
    final ownerName = grab.redpacketOwnerUsername ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HomeCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                RedpacketDetailScreen(redpacketId: grab.redpacketId),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            AvatarWidget(
              radius: 19,
              label: ownerName.isNotEmpty ? ownerName.substring(0, 1) : '?',
              color: AppColors.avatarColorFor(
                  grab.redpacketOwnerId ?? grab.redpacketId),
              imageUrl: grab.redpacketOwnerUserAvatarUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.redpacketCardFromLabel(ownerName),
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTimeFormatter(Localizations.localeOf(context))
                        .forConversationTile(
                      grab.createdAt.toLocal(),
                      timeJustNow: l10n.timeJustNow,
                      timeMinutesAgo: l10n.timeMinutesAgo,
                      timeYesterday: l10n.timeYesterday,
                    ),
                    style: TextStyle(fontSize: 12, color: AppColors.inkFaded),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              l10n.redpacketAmountYuan(MoneyFormatter.format(grab.grabAmount)),
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps a §9.7 status to its display text + accent color — mirrors
/// `RedpacketDetailScreen`'s `_StatusPill` mapping.
(String, Color) _statusDisplay(RedpacketStatus status, AppLocalizations l10n) {
  return switch (status) {
    RedpacketStatus.ongoing => (l10n.redpacketStatusOngoing, AppColors.success),
    RedpacketStatus.finished => (l10n.redpacketStatusFinished, AppColors.sage),
    RedpacketStatus.expired => (l10n.redpacketStatusExpired, AppColors.warning),
    RedpacketStatus.refunded =>
      (l10n.redpacketStatusRefunded, AppColors.inkFaded),
  };
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkFaded, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            // ignore: discarded_futures
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.redeem_outlined, size: 56, color: AppColors.inkFaint),
          const SizedBox(height: 12),
          Text(
            l10n.redpacketRecordsEmpty,
            style: TextStyle(
              color: AppColors.inkFaded,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
