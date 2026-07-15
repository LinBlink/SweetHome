import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/avatar_label.dart';
import '../core/error_messages.dart';
import '../core/home_widgets.dart';
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
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.contactsTitle),
      body: PaperBackground(
        child: FutureBuilder<List<FamilyMemberVm>>(
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
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
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
                          Icons.people_alt_rounded,
                          size: 36,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.contactsEmpty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.inkFaded,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 6, bottom: 24),
                itemCount: others.length,
                itemBuilder: (_, i) => _ContactTile(
                  member: others[i],
                  onTap: () => _startChat(others[i]),
                ),
              ),
            );
          },
        ),
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
        splashColor: AppColors.primary.withValues(alpha: 0.05),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _avatarColor.withValues(alpha: 0.35),
                        width: 1.4,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: AvatarWidget(
                      label: _label,
                      color: _avatarColor,
                      imageUrl: member.avatarUrl,
                      radius: 26,
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: _OnlineDot(userId: member.userId, viewer: auth),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
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
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}