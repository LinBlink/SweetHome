import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/error_messages.dart';
import '../core/home_widgets.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../providers/auth_provider.dart';
import '../providers/moment_provider.dart';
import '../widgets/error_banner.dart';
import '../widgets/moment_card.dart';
import 'moment_detail_screen.dart';
import 'publish_moment_screen.dart';

/// Family-feed screen (docs/api.md §7). Backed by [MomentProvider].
///
/// Loads the first page of the family's moments when entered, and
/// re-loads on pull-to-refresh. Pagination: [ScrollController]
/// triggers `loadMore` 200 px from the bottom of the list. The
/// publish FAB opens [PublishMomentScreen] which writes through the
/// provider's `publish()` pipeline (uploads every media draft then
/// fires §7.1 once).
class FamilyFeedScreen extends StatefulWidget {
  const FamilyFeedScreen({super.key});

  @override
  State<FamilyFeedScreen> createState() => _FamilyFeedScreenState();
}

class _FamilyFeedScreenState extends State<FamilyFeedScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MomentProvider>();
      if (provider.moments.isEmpty) provider.loadInitial();
    });
    _scroll.addListener(_onScroll);
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
      context.read<MomentProvider>().loadMore();
    }
  }

  Future<void> _confirmDelete(int momentId) async {
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<MomentProvider>().deleteMoment(momentId);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MomentProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.familyFeedTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<MomentProvider>(),
              child: const PublishMomentScreen(),
            ),
          ));
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.familyFeedPublishButton),
      ),
      body: PaperBackground(
        child: provider.isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: provider.refresh,
                child: provider.error != null
                    ? _ErrorBody(
                        message: provider.error!,
                        onDismiss: provider.clearError,
                      )
                    : provider.moments.isEmpty
                        ? const _EmptyFeed()
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.only(
                              top: 6,
                              bottom: 96,
                            ),
                            itemCount: provider.moments.length +
                                (provider.isLoadingMore ||
                                        provider.loadMoreError != null
                                    ? 1
                                    : 0),
                            itemBuilder: (ctx, i) {
                              if (i >= provider.moments.length) {
                                if (provider.loadMoreError != null) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: provider.loadMore,
                                        child: Text(
                                          provider.loadMoreError!,
                                          style: TextStyle(
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final m = provider.moments[i];
                              final isMine = currentUser != null &&
                                  m.userId == currentUser.userId;
                              return MomentCard(
                                moment: m,
                                isMine: isMine,
                                onDeleteTap:
                                    isMine ? () => _confirmDelete(m.id) : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChangeNotifierProvider.value(
                                      value: provider,
                                      child: MomentDetailScreen(moment: m),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  Icons.photo_library_outlined,
                  size: 44,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.familyFeedEmptyTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.familyFeedEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
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
