import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/error_messages.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/join_request.dart';
import '../providers/auth_provider.dart';
import '../services/family_service.dart';
import '../widgets/error_banner.dart';

/// Admin-side "Join Requests" inbox (docs/api.md §3.5.2-3.5.3).
/// Routed from the MyHome hub; only the family admin reaches it
/// (guarded at the MyHome tile by the `role == 'admin'` check).
class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  late Future<List<JoinRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<JoinRequest>> _load() {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.mockJoinRequests());
    }
    final familyId = context.read<AuthProvider>().currentUser?.familyId;
    if (familyId == null) return Future.value(const <JoinRequest>[]);
    final familyService = FamilyService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    return familyService.fetchJoinRequests(familyId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  /// Returns the reason the admin typed, or null if cancelled.
  Future<String?> _askForRejectReason(AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.joinRequestsAdminRejectDialogTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLength: 200,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.joinRequestsAdminRejectDialogReason,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.joinRequestsAdminRejectCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.joinRequestsAdminRejectSubmit),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(JoinRequest req) async {
    // Capture everything derived from context before the async gap so
    // navigation/snackbar/error handling don't depend on `context`
    // still being valid afterwards.
    final familyId = context.read<AuthProvider>().currentUser!.familyId;
    final familyService = FamilyService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (AppConfig.mockMode) {
        // No backend in mock mode — just simulate a short delay and
        // refresh; the snackbar comes from the real code path below.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        await familyService.approveJoinRequest(familyId, req.requestId);
      }
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.joinRequestsAdminApproveSuccess)));
      await _refresh();
    } on ApiException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(localizeErrorMessage(e.message, l10n))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))),
      );
    }
  }

  Future<void> _reject(JoinRequest req) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await _askForRejectReason(l10n);
    if (reason == null) return; // user cancelled
    if (!mounted) return;
    final familyId = context.read<AuthProvider>().currentUser!.familyId;
    final familyService = FamilyService(() {
      final user = context.read<AuthProvider>().currentUser;
      return user?.token ?? '';
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (AppConfig.mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        await familyService.rejectJoinRequest(
          familyId,
          req.requestId,
          reason: reason.isEmpty ? null : reason,
        );
      }
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.joinRequestsAdminRejectSuccess)));
      await _refresh();
    } on ApiException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(localizeErrorMessage(e.message, l10n))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))),
      );
    }
  }

  String _relationNounString(AppLocalizations l10n, RelationNoun n) {
    switch (n) {
      case RelationNoun.child:
        return l10n.relationNounChild;
      case RelationNoun.parent:
        return l10n.relationNounParent;
      case RelationNoun.spouse:
        return l10n.relationNounSpouse;
      case RelationNoun.sibling:
        return l10n.relationNounSibling;
      case RelationNoun.unknown:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.joinRequestsAdminTitle)),
      body: FutureBuilder<List<JoinRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            final isApi = snapshot.error is ApiException;
            return ErrorBanner(
              message: localizeErrorMessage(
                isApi
                    ? (snapshot.error as ApiException).message
                    : kNetworkErrorSentinel,
                l10n,
              ),
              onDismiss: _refresh,
            );
          }
          final requests = snapshot.data ?? const <JoinRequest>[];
          if (requests.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 96),
                    child: Center(
                      child: Text(
                        l10n.joinRequestsAdminEmpty,
                        style: const TextStyle(color: AppColors.textHint),
                      ),
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
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _RequestCard(
                request: requests[i],
                relationLabel: _relationNounString(l10n, requests[i].relationNoun),
                onApprove: () => _approve(requests[i]),
                onReject: () => _reject(requests[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final JoinRequest request;
  final String relationLabel; // pre-localized (e.g. "child" / "孩子")
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.relationLabel,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.joinRequestsAdminRelationLine(
                  request.targetMemberName, relationLabel),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${request.requesterName} · ${request.requesterPhone}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(request.createdAt.toLocal()),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.joinRequestsAdminMessage(request.message!),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: Text(l10n.joinRequestsAdminReject),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(l10n.joinRequestsAdminApprove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}