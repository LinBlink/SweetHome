import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../../core/error_messages.dart';
import '../../core/home_widgets.dart';
import '../../core/money/money_formatter.dart';
import '../../data/mock_data.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_exception.dart';
import '../../models/redpacket.dart';
import '../../providers/auth_provider.dart';
import '../../services/redpacket_service.dart';
import '../../widgets/avatar_widget.dart';

/// §9.2/§9.3/§9.4 detail page. Pushed from the chat-room red packet
/// card (or from the MyRedpackets hub). Layout:
///
/// - Top: big terracotta/red envelope with sender name + total amount.
/// - Status pill (ongoing / finished / expired / refunded).
/// - Either "Grab" button (if status is `ongoing` AND I haven't grabbed
///   AND I'm not the sender) OR a "you got ¥X.XX" line OR an
///   explanation of why the grab is unavailable.
/// - "Who has grabbed" section, lazily fetched on first scroll-past.
///
/// Per §9's preamble, the [RedpacketGrab.grabAmount] returned by §9.3
/// is the authoritative result — we display it *immediately* on grab
/// success rather than waiting for the §9.4 list to catch up.
class RedpacketDetailScreen extends StatefulWidget {
  final int redpacketId;

  /// Whether the red packet's conversation is a group chat — per the
  /// product rule, a group-chat sender CAN still grab a share of their
  /// own red packet (matches the "抢红包" real-world convention), but a
  /// direct (1:1) chat sender cannot (there's only one other person to
  /// give it to). Drives `_ActionArea`'s self-grab block below.
  ///
  /// Neither §9.1/§9.2's `RedpacketVO` nor §9.3/§9.4/§9.6's
  /// `RedpacketGrabVO` carry a `conversationId`, so callers that don't
  /// know the conversation (e.g. `RedpacketRecordsScreen`, navigating
  /// from the standalone "my red packets" history rather than from a
  /// specific chat room) can't look this up and pass `false` — the
  /// same restrictive behavior as before this flag existed.
  final bool isGroup;

  const RedpacketDetailScreen({
    super.key,
    required this.redpacketId,
    required this.isGroup,
  });

  @override
  State<RedpacketDetailScreen> createState() => _RedpacketDetailScreenState();
}

class _RedpacketDetailScreenState extends State<RedpacketDetailScreen> {
  // Sentinel value returned from `Iterable.firstWhere`'s `orElse` when
  // the mock user hasn't grabbed yet — caller compares `userId == 0`
  // (never a real user id) to know it's "not a real grab". Doesn't use
  // `id` for this check since `RedpacketGrab.id` is nullable and, per
  // §9.3, genuinely `null` on every real grab response — `null` isn't
  // available as an "absent" sentinel here. Non-const because
  // `RedpacketGrab`'s `createdAt` is a DateTime.
  static RedpacketGrab get _noGrab => RedpacketGrab(
        id: null,
        redpacketId: 0,
        userId: 0,
        grabAmount: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
  Redpacket? _redpacket;
  Future<Redpacket>? _loadFuture;
  bool _grabbing = false;
  String? _grabError;

  /// Set after a successful §9.3 grab — independent of `_redpacket`
  /// so we can show "you got ¥X.XX" without waiting for a fresh
  /// §9.2 round-trip to refresh the status.
  RedpacketGrab? _myGrab;

  Future<List<RedpacketGrab>>? _grabsFuture;
  List<RedpacketGrab> _grabs = [];

  @override
  void initState() {
    super.initState();
    _loadFuture = _fetchRedpacket();
    _grabsFuture = _fetchGrabs();
  }

  Future<Redpacket> _fetchRedpacket() async {
    if (AppConfig.mockMode) {
      final rp = MockDataSource.mockRedpacketById(widget.redpacketId);
      if (rp == null) {
        throw ApiException(404, 'INVALID_REDPACKET');
      }
      if (!mounted) return rp;
      setState(() => _redpacket = rp);
      return rp;
    }
    final token = context.read<AuthProvider>().currentUser!.token;
    final service = RedpacketService(() => token);
    final rp = await service.getById(widget.redpacketId);
    if (!mounted) return rp;
    setState(() => _redpacket = rp);
    return rp;
  }

  Future<List<RedpacketGrab>> _fetchGrabs() async {
    final List<RedpacketGrab> list;
    if (AppConfig.mockMode) {
      list = MockDataSource.mockRedpacketGrabs(widget.redpacketId);
    } else {
      final token = context.read<AuthProvider>().currentUser!.token;
      final service = RedpacketService(() => token);
      list = await service.listGrabs(widget.redpacketId);
    }
    if (!mounted) return list;
    final currentUserId = context.read<AuthProvider>().currentUser?.userId;
    setState(() {
      // `_grab()` splices an enriched (real name/avatar) version of
      // the current user's own row into `_grabs` the instant a grab
      // succeeds, ahead of the async DB write §9.4 reads from. If
      // *this* fetch is the background reconciliation `_grab()`
      // kicks off right after and the write still hasn't landed yet,
      // the fresh `list` won't have that row — replacing `_grabs`
      // wholesale would make the just-spliced name flicker away and
      // then reappear (or, if no further fetch ever runs, never
      // reappear) even though nothing is actually wrong. Preserve the
      // already-known row from the *old* `_grabs` in that case;
      // everyone else's rows still come straight from the fresh list.
      final alreadyInFreshList = list.any((g) => g.userId == currentUserId);
      final existingMine = currentUserId != null && !alreadyInFreshList
          ? _grabs.where((g) => g.userId == currentUserId)
          : const <RedpacketGrab>[];
      _grabs = existingMine.isEmpty ? list : [...list, existingMine.first];
      // If the server-confirmed list already has the current user's
      // own grab — e.g. reopening this screen after a *previous*
      // session already grabbed it, which is the common case this
      // fixes — reflect that in `_myGrab` too. Without this,
      // `_ActionArea` kept showing the grab button on every fresh
      // page load even for a red packet the user had already grabbed,
      // because `_myGrab` used to only ever get set inside `_grab()`'s
      // own success handler, never from history.
      if (currentUserId != null) {
        final mine = list.where((g) => g.userId == currentUserId);
        if (mine.isNotEmpty) _myGrab = mine.first;
      }
    });
    return list;
  }

  Future<void> _grab(AppLocalizations l10n) async {
    if (_grabbing) return;
    setState(() {
      _grabbing = true;
      _grabError = null;
    });
    try {
      RedpacketGrab grab;
      if (AppConfig.mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        // §9.3 already-grabbed guard — if the mock user already
        // grabbed id 1001 (per mockRedpacketGrabs), don't double
        // up; just show "you got ¥X.XX".
        final existing = _grabs.firstWhere(
          (g) => g.userId == 1,
          orElse: () => _noGrab,
        );
        if (existing.userId == 0) {
          grab = RedpacketGrab(
            id: 99999,
            redpacketId: widget.redpacketId,
            userId: 1,
            grabAmount: 888,
            createdAt: DateTime.now(),
            username: MockDataSource.mockUser.name,
          );
          MockDataSource.registerRedpacketGrab(widget.redpacketId, grab);
        } else {
          grab = existing;
        }
      } else {
        final authProvider = context.read<AuthProvider>();
        final token = authProvider.currentUser!.token;
        final service = RedpacketService(() => token);
        grab = await service.grab(widget.redpacketId);
        // §9.3's response doesn't echo the new balance back — refetch
        // `/users/me` so the profile card / send-form reflect the
        // credited `grabAmount` (mirrors the same refresh the §9.1
        // send flow does in `send_redpacket_screen.dart`). Fire-and-forget:
        // the grab result is already shown from the authoritative
        // `grabAmount` below, no need to block the UI on this round-trip.
        // ignore: discarded_futures
        authProvider.refreshBalance();
      }
      if (!mounted) return;
      final currentUser = context.read<AuthProvider>().currentUser;
      setState(() {
        // `grabAmount` is the authoritative, immediately-known result
        // (per the §9 preamble) — used for the "you got ¥X.XX" pill
        // right away, no round-trip needed for that part.
        _myGrab = grab;
        // Splice MY OWN row into the "who has grabbed" list right
        // now, rather than waiting for a fresh §9.4 fetch to surface
        // it: per the §9 preamble, the grab lands in Redis instantly
        // but the DB row §9.4 reads from is written asynchronously,
        // so re-querying immediately after this can still momentarily
        // miss this very grab — the list would otherwise look
        // "unrefreshed" right after grabbing (most noticeable when a
        // group sender grabs their own red packet and expects to see
        // themselves show up immediately). Unlike other people's
        // rows — whose name/avatar genuinely aren't known until the
        // list fetch fills them in — *my own* are already known from
        // `AuthProvider`, so there's no nameless "User#N" trade-off
        // here. Dedup on `userId`, not `id` (§9.3's response always
        // has `id: null` — see `RedpacketGrab.id`'s doc comment).
        final mine = RedpacketGrab(
          id: grab.id,
          redpacketId: grab.redpacketId,
          userId: grab.userId,
          grabAmount: grab.grabAmount,
          createdAt: grab.createdAt,
          username: currentUser?.name,
          userAvatarUrl: currentUser?.avatarUrl,
        );
        _grabs = [
          for (final g in _grabs)
            if (g.userId != grab.userId) g,
          mine,
        ];
        // Still re-fetch both in the background: the red packet's
        // `status` may now be `finished`, and the list refresh
        // reconciles this row with the server's real `id` once the
        // async DB write lands (and picks up anyone else who grabbed
        // concurrently).
        _loadFuture = _fetchRedpacket();
        _grabsFuture = _fetchGrabs();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _grabError = localizeErrorMessage(e.message, l10n));
    } catch (_) {
      if (!mounted) return;
      setState(() => _grabError =
          localizeErrorMessage(kNetworkErrorSentinel, l10n));
    } finally {
      if (mounted) setState(() => _grabbing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.watch<AuthProvider>().currentUser?.userId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.redpacketCardLabel)),
      body: SafeArea(
        child: FutureBuilder<Redpacket>(
          future: _loadFuture,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                _redpacket == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError && _redpacket == null) {
              return Center(
                child: Text(
                  localizeErrorMessage(
                      snap.error is ApiException
                          ? (snap.error as ApiException).message
                          : kNetworkErrorSentinel,
                      l10n),
                  style: TextStyle(color: AppColors.danger),
                ),
              );
            }
            final rp = _redpacket;
            if (rp == null) return const SizedBox.shrink();
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Envelope(
                    redpacket: rp,
                  ),
                  const SizedBox(height: 14),
                  _StatusPill(status: rp.status, l10n: l10n),
                  const SizedBox(height: 18),
                  _ActionArea(
                    redpacket: rp,
                    currentUserId: currentUserId,
                    isGroup: widget.isGroup,
                    myGrab: _myGrab,
                    grabbing: _grabbing,
                    errorText: _grabError,
                    onGrab: () => _grab(l10n),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 24),
                  HomeSectionHeader(
                    title: l10n.redpacketGrabListTitle,
                    accentIcon: Icons.group_outlined,
                  ),
                  _GrabsList(
                    grabsFuture: _grabsFuture,
                    grabs: _grabs,
                    total: rp.totalCount,
                    l10n: l10n,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Top half — a big terracotta/red "envelope" with the sender name +
/// total amount + count. Visual mirrors the in-chat `_RedpacketBubble`
/// at a larger scale (the chat version is condensed).
class _Envelope extends StatelessWidget {
  final Redpacket redpacket;
  const _Envelope({required this.redpacket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.redeem_rounded, size: 56, color: Colors.amber.shade100),
          const SizedBox(height: 6),
          Text(
            l10n.redpacketAmountYuan(
                MoneyFormatter.format(redpacket.totalAmount)),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.redpacketShareCountSuffix(redpacket.totalCount),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status pill — different colours per §9.5 state.
class _StatusPill extends StatelessWidget {
  final RedpacketStatus status;
  final AppLocalizations l10n;
  const _StatusPill({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RedpacketStatus.ongoing => (
          l10n.redpacketStatusOngoing,
          AppColors.success
        ),
      RedpacketStatus.finished => (
          l10n.redpacketStatusFinished,
          AppColors.sage
        ),
      RedpacketStatus.expired => (
          l10n.redpacketStatusExpired,
          AppColors.warning
        ),
      RedpacketStatus.refunded => (
          l10n.redpacketStatusRefunded,
          AppColors.inkFaded
        ),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// The grab button + result line, mutually exclusive. Walks through:
/// 1. I sent it in a direct (1:1) chat → "you sent this" notice, no
///    grab button — there's only the one other person to give it to.
///    In a *group* chat the sender can still grab a share of their own
///    red packet, so this step is skipped there.
/// 2. I've already grabbed → "you got ¥X.XX" + "already grabbed" notice.
/// 3. status != ongoing → status-specific notice ("expired" / "empty").
/// 4. otherwise → show the Grab button.
class _ActionArea extends StatelessWidget {
  final Redpacket redpacket;
  final int? currentUserId;
  final bool isGroup;
  final RedpacketGrab? myGrab;
  final bool grabbing;
  final String? errorText;
  final VoidCallback onGrab;
  final AppLocalizations l10n;

  const _ActionArea({
    required this.redpacket,
    required this.currentUserId,
    required this.isGroup,
    required this.myGrab,
    required this.grabbing,
    required this.errorText,
    required this.onGrab,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isSelf = currentUserId != null && redpacket.userId == currentUserId;
    if (isSelf && !isGroup) {
      return _Notice(text: l10n.redpacketSelfNotice);
    }
    if (myGrab != null) {
      return _GrabResult(
        amount: myGrab!.grabAmount,
        l10n: l10n,
      );
    }
    if (redpacket.status == RedpacketStatus.expired ||
        redpacket.status == RedpacketStatus.refunded) {
      return _Notice(text: l10n.redpacketExpiredNotice);
    }
    if (redpacket.status == RedpacketStatus.finished) {
      return _Notice(text: l10n.redpacketEmptyNotice);
    }
    // status == ongoing — show the grab button.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: grabbing ? null : onGrab,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: grabbing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  l10n.redpacketGrabButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorText!,
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

/// "You got ¥X.XX" pill — shown after a successful §9.3 grab. Uses
/// the *authoritative* `RedpacketGrab.grabAmount` rather than waiting
/// for the §9.4 list to catch up (per the §9 preamble note).
class _GrabResult extends StatelessWidget {
  final int amount;
  final AppLocalizations l10n;
  const _GrabResult({required this.amount, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.redpacketGrabSuccess(MoneyFormatter.format(amount)),
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain muted notice used when grab is unavailable (self-sent,
/// expired, etc).
class _Notice extends StatelessWidget {
  final String text;
  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.linen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.inkFaded, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Who has grabbed" pane. FutureBuilder shows the §9.4 list with the
/// initial `_grabs` already populated (so an immediate re-grab is
/// visible without a full refresh).
class _GrabsList extends StatelessWidget {
  final Future<List<RedpacketGrab>>? grabsFuture;
  final List<RedpacketGrab> grabs;
  final int total;
  final AppLocalizations l10n;

  const _GrabsList({
    required this.grabsFuture,
    required this.grabs,
    required this.total,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            l10n.redpacketGrabListCount(grabs.length, total),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.inkFaded,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        FutureBuilder<List<RedpacketGrab>>(
          future: grabsFuture,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                grabs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (grabs.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                alignment: Alignment.center,
                child: Text(
                  l10n.redpacketGrabListEmpty,
                  style: TextStyle(color: AppColors.inkFaded, fontSize: 13),
                ),
              );
            }
            return Column(
              children: [
                for (final g in grabs)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        AvatarWidget(
                          radius: 14,
                          // §9.4 fills `username`/`userAvatarUrl` (the
                          // grabber's info) — fall back to the bare
                          // userId only if a caller ever renders this
                          // list from a §9.3/§9.6 response, where that
                          // group is `null` by design.
                          label: (g.username?.isNotEmpty ?? false)
                              ? g.username!.substring(0, 1)
                              : '${g.userId}',
                          color: AppColors.avatarColorFor(g.userId),
                          imageUrl: g.userAvatarUrl,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            g.username ?? 'User #${g.userId}',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          l10n.redpacketAmountYuan(
                              MoneyFormatter.format(g.grabAmount)),
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}