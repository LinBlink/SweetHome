import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/avatar_label.dart';
import '../../core/error_messages.dart';
import '../../core/kinship/kinship_graph.dart';
import '../../core/kinship/kinship_localizer.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_exception.dart';
import '../../models/family_member_vm.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/avatar_widget.dart';
import 'chat_room_screen.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  late Future<List<FamilyMemberVm>> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthProvider>().loadFamilyMembers();
  }

  Future<void> _startChat(FamilyMemberVm member) async {
    if (_starting) return;
    // Capture everything derived from context before the async gap so the
    // navigation/error handling doesn't depend on `context` still being valid
    // afterwards.
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final chat = context.read<ChatProvider>();
    setState(() => _starting = true);
    try {
      final conv = await chat.startDirectConversation(member.userId);
      chat.setActiveConversation(conv.id);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: chat,
            child: ChatRoomScreen(conversationId: conv.id, conversationName: conv.name),
          ),
        ),
      );
    } on ApiException catch (e) {
      // Surface the real server-provided reason rather than a generic message.
      messenger.showSnackBar(SnackBar(content: Text(localizeErrorMessage(e.message, l10n))));
    } catch (_) {
      // Without this, a failure to create the conversation would leave the
      // tap doing nothing at all — surface it instead.
      messenger.showSnackBar(
          SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.userId;
    final appLocale = context.watch<LocaleProvider>().locale;
    final viewerGender = genderFromString(auth.currentUser?.gender);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.newConversationTitle)),
      body: FutureBuilder<List<FamilyMemberVm>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final members = (snapshot.data ?? const [])
              .where((m) => m.userId != currentUserId)
              .toList();
          return Stack(
            children: [
              ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 70),
                itemBuilder: (ctx, i) {
                  final member = members[i];
                  return ListTile(
                    leading: AvatarWidget(
                      label: memberAvatarLabel(member.name),
                      color: AppColors.avatarColorFor(member.userId),
                      imageUrl: member.avatarUrl,
                      radius: 22,
                    ),
                    title: Text(member.name),
                    subtitle: Text(
                      relationLabelFor(
                        relationCode: member.relationCode,
                        targetGender: member.gender,
                        viewerGender: viewerGender,
                        appLocale: appLocale,
                      ) ?? '',
                    ),
                    onTap: () => _startChat(member),
                  );
                },
              ),
              if (_starting)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
