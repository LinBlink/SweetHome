import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/time/app_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/moment.dart';
import '../providers/auth_provider.dart';
import '../providers/moment_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/moment_card.dart';

/// Single-moment detail screen. Renders the same content as a
/// [MomentCard] but full-width (no card chrome) plus two
/// bottom-sheet flows:
///
/// - Tap-to-open a "who liked this" sheet (§7.7).
/// - An inline comments section (§7.8/§7.9/§7.10) under the card,
///   with a fixed-bottom composer for posting and per-row delete
///   controls limited to the comment's author (per §7.10: only the
///   comment's author, not the moment's publisher).
class MomentDetailScreen extends StatefulWidget {
  final Moment moment;
  const MomentDetailScreen({super.key, required this.moment});

  @override
  State<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends State<MomentDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submittingComment = false;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MomentProvider>().fetchComments(widget.moment.id);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _submittingComment = true;
      _commentError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<MomentProvider>().addComment(widget.moment.id, text);
      _commentCtrl.clear();
    } on ApiException catch (e) {
      setState(() => _commentError = localizeErrorMessage(e.message, l10n));
    } catch (_) {
      setState(() => _commentError =
          localizeErrorMessage(kNetworkErrorSentinel, l10n));
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
    if (!mounted) return;
    if (_commentError != null) {
      messenger.showSnackBar(SnackBar(content: Text(_commentError!)));
    }
  }

  Future<void> _confirmDeleteComment(MomentComment c) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.momentCommentDeleteTitle),
        content: Text(l10n.momentCommentDeleteBody),
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
    try {
      await context
          .read<MomentProvider>()
          .deleteComment(widget.moment.id, c.id);
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(e.message, l10n))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.momentCommentDeleteFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final live = context.select<MomentProvider, Moment?>((p) {
      for (final m in p.moments) {
        if (m.id == widget.moment.id) return m;
      }
      return null;
    });
    final effective = live ?? widget.moment;
    final me = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.momentDetailTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MomentCard(
                    moment: effective,
                    isMine: me != null && effective.userId == me.userId,
                    onTap: () {
                      final momentProvider = context.read<MomentProvider>();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        // `showModalBottomSheet` inserts its content as a
                        // new sibling route on the same Navigator, not a
                        // descendant of this screen's own route — so it
                        // does NOT inherit the `MomentProvider` that only
                        // wraps the "home" route in `main.dart`'s
                        // `AuthGate`. Re-supply it explicitly here (same
                        // fix `family_feed_screen.dart` already applies
                        // when pushing a new route), or `_LikersSheet`'s
                        // `context.read<MomentProvider>()` in `initState`
                        // throws `ProviderNotFoundException`.
                        builder: (_) => ChangeNotifierProvider.value(
                          value: momentProvider,
                          child: _LikersSheet(momentId: effective.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _CommentsSection(
                    momentId: effective.id,
                    currentUserId: me?.userId,
                    onDelete: _confirmDeleteComment,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _CommentComposer(
            controller: _commentCtrl,
            submitting: _submittingComment,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final int momentId;
  final int? currentUserId;
  final Future<void> Function(MomentComment) onDelete;
  const _CommentsSection({
    required this.momentId,
    required this.currentUserId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MomentProvider>();
    final loading = provider.isCommentsLoading(momentId);
    final comments = provider.commentsOf(momentId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 0, 8),
            child: Text(
              l10n.momentCommentSectionTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (loading && comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (comments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text(
                  l10n.momentCommentEmpty,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            for (final c in comments) ...[
              _CommentRow(
                comment: c,
                isMine: currentUserId != null && c.userId == currentUserId,
                onDelete: () => onDelete(c),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final MomentComment comment;
  final bool isMine;
  final VoidCallback onDelete;
  const _CommentRow({
    required this.comment,
    required this.isMine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final time = AppTimeFormatter(locale).forRecordList(comment.createdAt.toLocal());
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWidget(
            label: memberAvatarLabel(comment.username),
            color: AppColors.avatarColorFor(comment.userId),
            imageUrl: comment.userAvatarUrl,
            radius: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.username,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isMine)
            IconButton(
              tooltip: l10n.familyFeedDeleteTitle,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;
  const _CommentComposer({
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => submitting ? null : onSubmit(),
                decoration: InputDecoration(
                  hintText: l10n.momentCommentInputHint,
                  filled: true,
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.momentCommentSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikersSheet extends StatefulWidget {
  final int momentId;
  const _LikersSheet({required this.momentId});

  @override
  State<_LikersSheet> createState() => _LikersSheetState();
}

class _LikersSheetState extends State<_LikersSheet> {
  Future<MomentLikeDetail>? _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<MomentProvider>().fetchLikeDetail(widget.momentId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              l10n.momentDetailWhoLikedTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<MomentLikeDetail>(
              future: _future,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
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
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.familyFeedLoadMoreError,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }
                final detail = snap.data!;
                if (detail.likers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        l10n.momentDetailNoLikes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: detail.likers.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final entry = detail.likers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.avatarColorFor(entry.userId),
                          child: Text(
                            entry.username.isEmpty
                                ? '?'
                                : entry.username[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(entry.username),
                        trailing: Text(
                          l10n.momentDetailLikedTimes(entry.likeCount),
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}