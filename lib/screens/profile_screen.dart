import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/language_picker.dart';
import 'edit_profile_screen.dart';
import 'family_members_screen.dart';
import 'join_family_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: Column(
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            child: _buildProfileHeader(
              name: user?.name ?? '',
              familyName: user?.familyName ?? '',
              avatarUrl: user?.avatarUrl,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.people_outline, color: AppColors.primary),
            title: Text(l10n.profileFamilyMembersRow),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () {
              // ChatProvider lives below the root Navigator (created in
              // AuthGate) and is used by the family-members screen to show
              // the live online dot per member. A pushed route doesn't
              // inherit that scope, so re-provide it explicitly — same
              // pattern as conversation_list_screen's push to
              // NewConversationScreen/ChatRoomScreen.
              final chat = context.read<ChatProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: chat,
                    child: const FamilyMembersScreen(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined, color: AppColors.primary),
            title: Text(l10n.joinFamilyTitle),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _LanguageRow(l10n: l10n),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmLogout(context, l10n),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.profileLogout,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String name,
    required String familyName,
    String? avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          AvatarWidget(
            label: name.isEmpty ? '家' : name[0],
            color: AppColors.primaryDark,
            imageUrl: avatarUrl,
            radius: 40,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(
                familyName,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.profileLogout,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.profileLogoutConfirmMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.profileLogout),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final AppLocalizations l10n;
  const _LanguageRow({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LocaleProvider>().locale;
    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.primary),
      title: Text(l10n.profileLanguageRow),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localeDisplayName(current), style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
      onTap: () => showLanguagePickerSheet(context),
    );
  }
}
