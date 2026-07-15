import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/moment.dart';
import '../providers/moment_provider.dart';
import '../widgets/moment_card.dart';

/// Single-moment detail screen. Renders the same content as a
/// [MomentCard] but full-width (no card chrome) plus a bottom-sheet
/// "who liked this" sheet backed by [MomentProvider.fetchLikeDetail]
/// (§7.7).
class MomentDetailScreen extends StatelessWidget {
  final Moment moment;
  const MomentDetailScreen({super.key, required this.moment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final live = context.select<MomentProvider, Moment?>((p) {
      for (final m in p.moments) {
        if (m.id == moment.id) return m;
      }
      return null;
    });
    final effective = live ?? moment;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.momentDetailTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: MomentCard(
          moment: effective,
          isMine: false,
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) =>
                  _LikersSheet(momentId: effective.id),
            );
          },
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
                        trailing: entry.likeCount > 1
                            ? Text(
                                l10n.familyFeedLikeCount(entry.likeCount),
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                              )
                            : null,
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
