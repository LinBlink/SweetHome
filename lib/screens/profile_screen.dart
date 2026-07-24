import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_palette.dart';
import '../core/avatar_label.dart';
import '../core/home_widgets.dart';
import '../core/money/money_formatter.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/language_picker.dart';
import 'chat_export_screen.dart';
import 'edit_profile_screen.dart';
import 'family_members_screen.dart';
import 'join_family_screen.dart';
import 'storage_settings_screen.dart';

/// "我的" tab — profile, family management, language, logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.navProfile),
      body: PaperBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _ProfileCard(
              name: user?.name ?? '',
              familyName: user?.familyName ?? '',
              avatarUrl: user?.avatarUrl,
              balance: user?.balance ?? 0,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 18),
            HomeSectionHeader(
              title: l10n.profileSectionFamilyTitle,
              accentIcon: Icons.diversity_3_rounded,
            ),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () {
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
              child: HomeListItem(
                leading: _LeadingIcon(
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                ),
                title: l10n.profileFamilyMembersRow,
                subtitle: l10n.profileFamilyMembersSubtitle,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 12),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
              ),
              child: HomeListItem(
                leading: const _LeadingIcon(
                  icon: Icons.qr_code_2_rounded,
                  color: AppColors.sage,
                ),
                title: l10n.joinFamilyTitle,
                subtitle: l10n.profileJoinFamilySubtitle,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 22),
            HomeSectionHeader(
              title: l10n.profileSectionSettingsTitle,
              accentIcon: Icons.settings_rounded,
            ),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () => showThemePickerSheet(context),
              child: HomeListItem(
                leading: _LeadingIcon(
                  icon: Icons.palette_rounded,
                  color: AppColors.primaryDark,
                ),
                title: l10n.profileThemeRow,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _paletteDisplayName(
                        context.watch<ThemeProvider>().palette,
                      ),
                      style: TextStyle(
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.inkFaded,
                      size: 20,
                    ),
                  ],
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 10),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () => showAppearancePickerSheet(context),
              child: HomeListItem(
                leading: _LeadingIcon(
                  icon: Icons.dark_mode_rounded,
                  color: AppColors.primaryDark,
                ),
                title: l10n.profileAppearanceRow,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _themeModeDisplayName(
                        context.watch<ThemeProvider>().themeMode,
                        l10n,
                      ),
                      style: TextStyle(
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.inkFaded,
                      size: 20,
                    ),
                  ],
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 10),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () => showLanguagePickerSheet(context),
              child: HomeListItem(
                leading: _LeadingIcon(
                  icon: Icons.translate_rounded,
                  color: AppColors.primaryDark,
                ),
                title: l10n.profileLanguageRow,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localeDisplayName(
                        context.watch<LocaleProvider>().locale,
                      ),
                      style: TextStyle(
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.inkFaded,
                      size: 20,
                    ),
                  ],
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 10),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StorageSettingsScreen(),
                ),
              ),
              child: HomeListItem(
                leading: _LeadingIcon(
                  icon: Icons.delete_sweep_rounded,
                  color: AppColors.danger,
                ),
                title: l10n.profileStorageRow,
                subtitle: l10n.profileStorageSubtitle,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 10),
            HomeCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatExportScreen(),
                ),
              ),
              child: HomeListItem(
                leading: _LeadingIcon(
                  icon: Icons.ios_share_rounded,
                  color: AppColors.sage,
                ),
                title: l10n.profileExportChatRow,
                subtitle: l10n.profileExportChatSubtitle,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
                showSeparator: false,
              ),
            ),
            const SizedBox(height: 28),
            // Logout — sits low on the profile, terracotta-outlined
            // ghost button so it's clearly destructive but not loud.
            OutlinedButton(
              onPressed: () => _confirmLogout(context, l10n),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.6),
                  width: 1.4,
                ),
                foregroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                l10n.profileLogout,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.profileLogout,
          style: TextStyle(color: AppColors.ink),
        ),
        content: Text(
          l10n.profileLogoutConfirmMessage,
          style: TextStyle(color: AppColors.inkFaded, height: 1.5),
        ),
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

/// Bottom-sheet color picker. Shows each preset as a circle
/// swatch next to its localized name; tapping commits the
/// selection. The currently active preset is marked with a ring.
/// Kept separate from [showAppearancePickerSheet] — color palette
/// and light/dark mode are independent settings, not sub-sections
/// of one sheet.
void showThemePickerSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final provider = context.read<ThemeProvider>();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              l10n.profileThemeSheetTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final p in AppPalette.presets)
              ListTile(
                leading: _ThemeSwatch(
                  palette: p,
                  selected: p.id == provider.palette.id,
                ),
                title: Text(_paletteDisplayName(p)),
                trailing: p.id == provider.palette.id
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  provider.setPalette(p);
                  Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Bottom-sheet appearance (light/dark/system) picker — separate from
/// the color-palette sheet above so switching day/night mode isn't
/// bundled with picking a brand color.
void showAppearancePickerSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final provider = context.read<ThemeProvider>();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              l10n.profileAppearanceSheetTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  switch (mode) {
                    ThemeMode.system => Icons.brightness_auto_rounded,
                    ThemeMode.light => Icons.light_mode_rounded,
                    ThemeMode.dark => Icons.dark_mode_rounded,
                  },
                  color: AppColors.primary,
                ),
                title: Text(switch (mode) {
                  ThemeMode.system => l10n.profileThemeModeSystem,
                  ThemeMode.light => l10n.profileThemeModeLight,
                  ThemeMode.dark => l10n.profileThemeModeDark,
                }),
                trailing: mode == provider.themeMode
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  provider.setThemeMode(mode);
                  Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

String _themeModeDisplayName(ThemeMode mode, AppLocalizations l10n) {
  return switch (mode) {
    ThemeMode.system => l10n.profileThemeModeSystem,
    ThemeMode.light => l10n.profileThemeModeLight,
    ThemeMode.dark => l10n.profileThemeModeDark,
  };
}

String _paletteDisplayName(AppPalette p) {
  switch (p.id) {
    case 'terracotta':
      return 'Terracotta 赭';
    case 'ocean':
      return 'Ocean 溟';
    case 'forest':
      return 'Forest 翠';
    case 'lavender':
      return 'Lavender 黛';
    case 'slate':
      return 'Slate 苍';
    default:
      return p.id;
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  const _ThemeSwatch({required this.palette, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primaryLight, palette.primary],
        ),
        border: Border.all(
          color: selected ? AppColors.ink : AppColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

/// A "letter-pressed" profile card at the top of the profile tab —
/// wood-grain background, linen border, ink-stamp feel.
class _ProfileCard extends StatelessWidget {
  final String name;
  final String familyName;
  final String? avatarUrl;
  final int balance;
  final VoidCallback onTap;
  const _ProfileCard({
    required this.name,
    required this.familyName,
    required this.avatarUrl,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.linen, width: 3),
                ),
                padding: const EdgeInsets.all(2),
                child: AvatarWidget(
                  label: name.isEmpty
                      ? '?'
                      : memberAvatarLabel(name),
                  color: AppColors.primary,
                  imageUrl: avatarUrl,
                  radius: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.cottage_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            familyName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Balance pill — §2.1 wallet balance rendered
                    // inside the profile card so the user can see it
                    // at a glance without opening Edit Profile. A
                    // wallet icon (matches the edit-profile row)
                    // + the formatted amount; localized via
                    // `balanceValue` so the `¥` symbol can later be
                    // overridden per-locale.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.balanceValue(MoneyFormatter.format(balance)),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.edit_outlined,
                color: Color(0xCCEFE0D0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _LeadingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 20),
    );
  }
}

