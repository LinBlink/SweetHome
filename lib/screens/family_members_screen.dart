import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/invite_expiry.dart';
import '../core/kinship/kinship_graph.dart';
import '../core/kinship/kinship_localizer.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/avatar_widget.dart';
import 'chat/chat_room_screen.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  late Future<List<FamilyMemberVm>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthProvider>().loadFamilyMembers();
  }

  Future<void> _showInviteDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    InviteCodeInfo? info;
    String? error;
    try {
      info = await auth.generateInviteCode();
    } catch (_) {
      error = l10n.errorNetworkFailed;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.inviteGenerate, style: const TextStyle(color: AppColors.textPrimary)),
        content: error != null
            ? Text(error, style: const TextStyle(color: AppColors.danger))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.inviteCodeLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  SelectableText(
                    info!.inviteCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    InviteExpiry.remaining(ctx, info.expiresAt.toLocal()),
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          if (info != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: info!.inviteCode));
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.inviteCopied)));
                Navigator.pop(ctx);
              },
              child: Text(l10n.inviteCopy),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = context.watch<AuthProvider>().currentUser?.role == 'admin';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.familyMembersTitle),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: l10n.inviteGenerate,
              onPressed: () => _showInviteDialog(context),
            ),
        ],
      ),
      body: FutureBuilder<List<FamilyMemberVm>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final members = snapshot.data ?? const [];
          // Seed ChatProvider's online-status set from the §3.2
          // REST `isOnline` field so the initial render doesn't
          // show every member as offline until a `USER_STATUS`
          // WS frame arrives. Subsequent WS frames still own the
          // truth (a member can come online/offline between the
          // member-list fetch and the chat connection), so this
          // is additive — `_onlineUserIds.add` is a no-op if the
          // id is already present.
          final chat = context.read<ChatProvider>();
          for (final m in members) {
            if (m.isOnline) chat.markUserOnline(m.userId);
          }
          return ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
            itemBuilder: (ctx, i) => _MemberTile(member: members[i], l10n: l10n),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final FamilyMemberVm member;
  final AppLocalizations l10n;

  const _MemberTile({required this.member, required this.l10n});

  // Falls back to the member's name abbreviation (see
  // `memberAvatarLabel`) when no `avatarUrl` is set or the image fails
  // to load — the AvatarWidget's `errorBuilder` handles the latter.
  String get _avatarLabel => memberAvatarLabel(member.name);

  @override
  Widget build(BuildContext context) {
    final appLocale = context.watch<LocaleProvider>().locale;
    final auth = context.watch<AuthProvider>();
    final viewerGender = genderFromString(auth.currentUser?.gender);
    final currentUserId = auth.currentUser?.userId;
    final avatarColor =
        AppColors.avatarColorFor(member.userId, selfUserId: currentUserId);
    final relationLabel = relationLabelFor(
      relationCode: member.relationCode,
      targetGender: member.gender,
      viewerGender: viewerGender,
      appLocale: appLocale,
    );
    // Self has no one to chat with — render the row as a plain,
    // non-interactive entry. Everyone else wraps the body in Material
    // + InkWell so the Material ripple actually paints (an InkWell
    // directly on a Padding in a ListView.separated silently no-ops
    // because there's no `Material` ancestor at the tap surface).
    final isSelf = currentUserId != null && member.userId == currentUserId;
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(
                label: _avatarLabel,
                color: avatarColor,
                imageUrl: member.avatarUrl,
                radius: 26,
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Selector<ChatProvider, bool>(
                  selector: (_, chat) => chat.isUserOnline(member.userId),
                  builder: (_, isOnline, _) => isOnline
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (member.role == 'admin') ...[
                      const SizedBox(width: 8),
                      _AdminBadge(label: l10n.familyMembersAdminBadge),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  relationLabel ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (isSelf) return body;
    // Material wrapper is required — without it InkWell's ripple has
    // nowhere to paint (ListView.separated's item surface isn't a
    // Material ancestor at the row level).
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startChat(context),
        child: body,
      ),
    );
  }

  /// Same flow as `_NewConversationScreenState._startChat` — start (or
  /// reuse) a 1:1 conversation with this member and push the chat
  /// room, re-providing `ChatProvider` because the pushed route
  /// doesn't inherit the provider scope from the family-members
  /// screen (see the corresponding note on profile_screen.dart).
  Future<void> _startChat(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final chat = context.read<ChatProvider>();
    try {
      final conv = await chat.startDirectConversation(member.userId);
      chat.setActiveConversation(conv.id);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: chat,
            child: ChatRoomScreen(
              conversationId: conv.id,
              conversationName: conv.name,
            ),
          ),
        ),
      );
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
}

class _AdminBadge extends StatelessWidget {
  final String label;
  const _AdminBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
