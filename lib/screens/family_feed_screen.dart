import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/error_messages.dart';
import '../core/home_widgets.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/moment.dart';
import '../providers/auth_provider.dart';
import '../providers/moment_provider.dart';
import '../widgets/error_banner.dart';
import '../widgets/moment_card.dart';
import 'moment_detail_screen.dart';
import 'publish_moment_screen.dart';

/// Family-feed screen (docs/api.md §7). Backed by [MomentProvider].
///
/// This widget hosts TWO sub-feeds as in-tab pages — §7.2 family-only
/// ("自个儿家") and §7.3 cross-family public ("串串门") — switched
/// via a local [TabController] driving an [IndexedStack]. Unlike the
/// previous outer-[PageView] approach, scope switching stays entirely
/// inside this screen, so the outer [MainShell] PageView keeps its
/// five-tab layout (Messages / Contacts / MyHome / FamilyFeed /
/// Profile).
///
/// Horizontal swipe is intercepted here so that:
///  - dragging *within* the scope pair (自个儿家 ↔ 串串门) hops to
///    the other scope the way the old swipe-between-pages shell
///    did;
///  - dragging *out of* the pair (right-drag from 自个儿家,
///    left-drag from 串串门) forwards to [onSwipeToPrevPage] /
///    [onSwipeToNextPage] so [MainShell] animates its outer PageView
///    to the left/right neighbour (MyHome / Profile).
/// Tab-strip taps still work for explicit, no-guess switching.
///
/// The active subtab is **globally sticky**:
/// `MomentProvider.setActiveFeedScope` writes through to
/// `SharedPreferences` keyed by userId so a re-launch / re-login
/// on the same device keeps the user's last choice instead of
/// snapping back to family. See `MomentFeedScope` for the
/// persistence contract.
class FamilyFeedScreen extends StatefulWidget {
  /// Drag rightward (finger →) past the left-most scope (自个儿家)
  /// asks the outer [MainShell] PageView to hop to its left
  /// neighbour page (MyHome). Wired in `main.dart`.
  final VoidCallback? onSwipeToPrevPage;

  /// Drag leftward (finger ←) past the right-most scope (串串门)
  /// asks the outer [MainShell] PageView to hop to its right
  /// neighbour page (Profile). Wired in `main.dart`.
  final VoidCallback? onSwipeToNextPage;

  const FamilyFeedScreen({
    super.key,
    this.onSwipeToPrevPage,
    this.onSwipeToNextPage,
  });

  @override
  State<FamilyFeedScreen> createState() => _FamilyFeedScreenState();
}

class _FamilyFeedScreenState extends State<FamilyFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MomentProvider>();
    final initialIndex =
        provider.activeFeedScope == MomentFeedScope.public ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // TabController fires both while the user is mid-drag
    // (indexIsChanging == true) and once the animation settles.
    // Only persist on the settled pass to avoid writing
    // SharedPreferences on every intermediate frame (and to skip
    // the spurious notify from the initial-index assignment that
    // happens in the constructor). The setState is for the
    // IndexedStack below — TabBarView would track the controller
    // automatically, but IndexedStack is a static layout widget so
    // we have to nudge a rebuild when the controller's settled
    // index changes.
    if (_tabController.indexIsChanging) return;
    final scope = _tabController.index == 1
        ? MomentFeedScope.public
        : MomentFeedScope.family;
    context.read<MomentProvider>().setActiveFeedScope(scope);
    if (mounted) setState(() {});
  }

  /// Decide what a horizontal drag-end should do based on which
  /// scope is currently shown and the drag's primary velocity:
  ///
  ///   velocity > 0 (finger moved right, user wants the *left*
  ///   neighbour):
  ///     - scope 0 (自个儿家) → outer hop to MyHome
  ///     - scope 1 (串串门) → inner hop to 自个儿家
  ///
  ///   velocity < 0 (finger moved left, user wants the *right*
  ///   neighbour):
  ///     - scope 0 (自个儿家) → inner hop to 串串门
  ///     - scope 1 (串串门) → outer hop to Profile
  ///
  /// The 250 px/s gate matches Material's default for "toss" swipes —
  /// anything slower is treated as a no-op so a slow scroll-jitter
  /// on a list (a drag that happened to tilt horizontal during a
  /// vertical ListView scroll) doesn't accidentally page away. The
  /// outer-hop branch is a fire-and-forget `animateTo`: the parent
  /// MainShell owns the PageController so we don't touch it here.
  static const double _kSwipeVelocityThreshold = 250.0;

  void _onHorizontalDragEnd(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < _kSwipeVelocityThreshold) return;
    final atFamily = _tabController.index == 0;
    if (v > 0) {
      // Finger rightward → user wants the left neighbour of the
      // current scope pair.
      if (atFamily) {
        widget.onSwipeToPrevPage?.call();
      } else {
        _tabController.animateTo(0);
      }
    } else {
      // Finger leftward → user wants the right neighbour.
      if (atFamily) {
        _tabController.animateTo(1);
      } else {
        widget.onSwipeToNextPage?.call();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MomentProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<MomentProvider>(),
              child: const PublishMomentScreen(),
            ),
          ));
        },
        // Unique hero tag — MainShell's center-docked FAB is also in
        // the same route subtree, and two FABs with the default tag
        // crash the Hero overlay during page transitions.
        heroTag: 'family-feed-publish-fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.familyFeedPublishButton),
      ),
      body: SafeArea(
        // top: true keeps the tab strip below the status bar / notch.
        // The bottom inset is owned by [MainShell]'s nav bar, which
        // the PageView already excludes via [TabVisibility] + the
        // shell's own SafeArea around the nav.
        top: true,
        bottom: false,
        child: PaperBackground(
          child: Column(
            children: [
              _FeedScopeTabs(controller: _tabController),
              Expanded(
                child: GestureDetector(
                  // Capture horizontal drag so the outer [PageView]
                  // doesn't also receive it — without this the inner
                  // scope-swipe and the outer tab-swipe would both
                  // fire and fight over the same gesture. We then
                  // decide here whether the swipe was an *intra-pair*
                  // drag (self→self hop to the other scope, handled
                  // by the TabController) or an *out-of-pair* drag
                  // (forward to [widget.onSwipeToPrevPage /
                  // onSwipeToNextPage] so MainShell animates to MyHome
                  // / Profile). Only horizontal drag is hooked so
                  // vertical ListView scrolling inside the feed body
                  // keeps working normally.
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  child: IndexedStack(
                    index: _tabController.index,
                    children: [
                      _FeedListBody(
                        loader: provider.loadInitial,
                        refresher: provider.refresh,
                        loadMore: provider.loadMore,
                        moments: provider.moments,
                        isInitialLoading: provider.isInitialLoading,
                        isRefreshing: provider.isRefreshing,
                        isLoadingMore: provider.isLoadingMore,
                        hasMore: provider.hasMore,
                        error: provider.error,
                        loadMoreError: provider.loadMoreError,
                        emptyTitle: l10n.familyFeedEmptyTitle,
                        emptyDesc: l10n.familyFeedEmptyDesc,
                        loadMoreErrorFallback: l10n.familyFeedLoadMoreError,
                        emptyIcon: Icons.photo_library_outlined,
                        onClearError: provider.clearError,
                        onCardTap: (m) => _openMoment(context, provider, m),
                        onDeleteTap: (m) =>
                            _confirmDelete(context, provider, m.id),
                      ),
                      _FeedListBody(
                        loader: provider.loadInitialPublic,
                        refresher: provider.refreshPublic,
                        loadMore: provider.loadMorePublic,
                        moments: provider.publicMoments,
                        isInitialLoading: provider.isPublicInitialLoading,
                        isRefreshing: provider.isPublicRefreshing,
                        isLoadingMore: provider.isPublicLoadingMore,
                        hasMore: provider.hasMorePublic,
                        error: provider.publicError,
                        loadMoreError: provider.publicLoadMoreError,
                        emptyTitle: l10n.publicMomentsEmptyTitle,
                        emptyDesc: l10n.publicMomentsEmptyDesc,
                        loadMoreErrorFallback: l10n.publicMomentsLoadMoreError,
                        emptyIcon: Icons.public_rounded,
                        onClearError: provider.clearPublicError,
                        onCardTap: (m) => _openMoment(context, provider, m),
                        onDeleteTap: (m) =>
                            _confirmDelete(context, provider, m.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── navigation helpers (kept as instance methods so both tab
  // ── bodies don't have to duplicate them) ────────────────────────
  void _openMoment(
    BuildContext context,
    MomentProvider provider,
    Moment m,
  ) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: MomentDetailScreen(moment: m),
      ),
    ));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MomentProvider provider,
    int momentId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.familyFeedDeleteTitle),
        content: Text(l10n.familyFeedDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.familyFeedDeleteConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteMoment(momentId);
      messenger.showSnackBar(SnackBar(content: Text(l10n.familyFeedDeleted)));
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(e.message, l10n))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.familyFeedLoadMoreError)),
      );
    }
  }
}

/// The "自个儿家 / 串串门" tab strip. Pure UI — taps animate the
/// parent's [TabController]; the controller drives the [TabBarView]
/// inside the screen, not the outer [MainShell] PageView. Listens to
/// the controller so the active-tab underline follows drags as well
/// as taps (a drag fires `indexIsChanging` frames then a settle
/// frame, and we rebuild on each one).
class _FeedScopeTabs extends StatefulWidget {
  final TabController controller;

  const _FeedScopeTabs({required this.controller});

  @override
  State<_FeedScopeTabs> createState() => _FeedScopeTabsState();
}

class _FeedScopeTabsState extends State<_FeedScopeTabs> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(covariant _FeedScopeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: l10n.familyFeedScopeMyFamily,
                  active: widget.controller.index == 0,
                  onTap: () => widget.controller.animateTo(0),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: l10n.familyFeedScopeOthers,
                  active: widget.controller.index == 1,
                  onTap: () => widget.controller.animateTo(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.inkFaded,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5,
            width: active ? 24 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared list-rendering body for both family and public feeds.
/// Drives the same fetch / refresh / load-more / list / pagination
/// state as before — parameterised on whichever scope's list /
/// callbacks the parent passes in — so the same widget body powers
/// both in-tab children. Mounts its own scroll controller and
/// triggers its own first-page fetch the first time the underlying
/// list is empty (so a tab that's never been viewed loads lazily
/// the first time the user swipes into it).
class _FeedListBody extends StatefulWidget {
  final Future<void> Function() loader;
  final Future<void> Function() refresher;
  final Future<void> Function() loadMore;
  final List<Moment> moments;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? loadMoreError;
  final String emptyTitle;
  final String emptyDesc;
  final String loadMoreErrorFallback;
  final IconData emptyIcon;
  final VoidCallback onClearError;
  final ValueChanged<Moment> onCardTap;
  final ValueChanged<Moment> onDeleteTap;

  const _FeedListBody({
    required this.loader,
    required this.refresher,
    required this.loadMore,
    required this.moments,
    required this.isInitialLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.loadMoreError,
    required this.emptyTitle,
    required this.emptyDesc,
    required this.loadMoreErrorFallback,
    required this.emptyIcon,
    required this.onClearError,
    required this.onCardTap,
    required this.onDeleteTap,
  });

  @override
  State<_FeedListBody> createState() => _FeedListBodyState();
}

class _FeedListBodyState extends State<_FeedListBody> {
  final ScrollController _scroll = ScrollController();
  bool _kickedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Kick the first-page fetch the first time this body mounts with
    // an empty list. The provider's loader early-returns on a non-empty
    // list, so re-mounting (e.g. rotating the outer PageView back to
    // this tab) doesn't re-fetch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _kickedInitialLoad) return;
      _kickedInitialLoad = true;
      if (widget.moments.isEmpty && !widget.isInitialLoading) {
        widget.loader();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      if (widget.hasMore && !widget.isLoadingMore) {
        widget.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    if (widget.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.refresher,
        child: _ErrorBody(
          message: widget.error!,
          onDismiss: widget.onClearError,
        ),
      );
    }
    if (widget.moments.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: widget.refresher,
        child: _EmptyFeed(
          title: widget.emptyTitle,
          desc: widget.emptyDesc,
          icon: widget.emptyIcon,
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.refresher,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 6, bottom: 96),
        itemCount: widget.moments.length +
            ((!widget.hasMore ||
                    widget.loadMoreError != null ||
                    widget.isLoadingMore)
                ? 1
                : 0),
        itemBuilder: (ctx, i) {
          if (i == widget.moments.length) {
            if (widget.loadMoreError != null && widget.hasMore) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: widget.loadMore,
                    child: Text(
                      widget.loadMoreError ?? widget.loadMoreErrorFallback,
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ),
              );
            }
            if (!widget.hasMore) {
              return const SizedBox(height: 24);
            }
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final m = widget.moments[i];
          final isMine =
              currentUser != null && m.userId == currentUser.userId;
          return MomentCard(
            moment: m,
            isMine: isMine,
            onDeleteTap: isMine ? () => widget.onDeleteTap(m) : null,
            onTap: () => widget.onCardTap(m),
          );
        },
      ),
    );
  }
}

/// Show the empty-state hero on either tab. Drives the same shape
/// as the original `_EmptyFeed`, just with a plumbed-through icon
/// so the public tab can use `Icons.public_rounded` instead of the
/// photo library.
class _EmptyFeed extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  const _EmptyFeed({
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.linen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 44,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkFaded,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBody({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ErrorBanner(message: message, onDismiss: onDismiss),
      ],
    );
  }
}