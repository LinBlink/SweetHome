import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/error_banner.dart';
import 'chat/chat_room_screen.dart';

/// Bottom-nav "Contacts" tab — a streamlined "find someone to chat
/// with" view of the family. Distinct from `FamilyMembersScreen`
/// (which lives under the Profile tab and is admin-oriented —
/// generates invite codes, shows the admin badge, shows kinship
/// terms). Contacts strips all of that down to: name + avatar +
/// online dot → tap to start a 1:1 chat.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Future<List<FamilyMemberVm>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FamilyMemberVm>> _load() {
    return context.read<AuthProvider>().loadFamilyMembers();
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _startChat(FamilyMemberVm member) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final chat = context.read<ChatProvider>();
    try {
      final conv = await chat.startDirectConversation(member.userId);
      chat.setActiveConversation(conv.id);
      // ChatRoomScreen reads ChatProvider but doesn't auto-inherit it
      // from the pushed route — re-provide explicitly (same pattern
      // used by NewConversationScreen / FamilyMembersScreen).
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
          SnackBar(content: Text(localizeErrorMessage(e.message, l10n))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = context.watch<AuthProvider>().currentUser?.userId;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.contactsTitle)),
      body: FutureBuilder<List<FamilyMemberVm>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return ErrorBanner(
              message: localizeErrorMessage(
                (snapshot.error is ApiException)
                    ? (snapshot.error as ApiException).message
                    : kNetworkErrorSentinel,
                l10n,
              ),
              onDismiss: _refresh,
            );
          }
          // Filter self out — chatting with yourself is meaningless
          // and the family-member list always includes the current
          // user.
          final others = (snapshot.data ?? const [])
              .where((m) => m.userId != currentUserId)
              .toList();
          if (others.isEmpty) {
            return Center(
              child: Text(
                l10n.contactsEmpty,
                style: const TextStyle(color: AppColors.textHint),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: others.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
              itemBuilder: (_, i) => _ContactTile(
                member: others[i],
                onTap: () => _startChat(others[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final FamilyMemberVm member;
  final VoidCallback onTap;

  const _ContactTile({required this.member, required this.onTap});

  Color get _avatarColor => AppColors.avatarColorFor(member.userId);

  String get _label => memberAvatarLabel(member.name);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarWidget(
                    label: _label,
                    color: _avatarColor,
                    imageUrl: member.avatarUrl,
                    radius: 26,
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: _OnlineDot(userId: member.userId, viewer: auth),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  final int userId;
  final AuthProvider viewer;

  const _OnlineDot({required this.userId, required this.viewer});

  @override
  Widget build(BuildContext context) {
    return Selector<ChatProvider, bool>(
      selector: (_, chat) => chat.isUserOnline(userId),
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
    );
  }
}