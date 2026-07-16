import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../core/app_palette.dart';
import '../core/avatar_label.dart';
import '../core/home_widgets.dart';
import '../data/mock_data.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../services/family_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/language_picker.dart';
import 'edit_profile_screen.dart';
import 'family_members_screen.dart';
import 'join_family_screen.dart';
import 'join_requests_screen.dart';

/// "我的" tab — profile, family management, language, logout. Also
/// hosts admin-only "Join Requests" — the family admin reviews and
/// approves / rejects pending join submissions here (docs/api.md
/// §3.5.2-§3.5.3). Non-admins don't see the row at all.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Pending join-request count for the admin badge. Only meaningful
  /// when `currentUser.role == 'admin'`; non-admins leave it null
  /// so the FutureBuilder shows nothing.
  Future<int>? _pendingCount;

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  Future<void> _refreshPending() async {
    final user = context.read<AuthProvider>().currentUser;
    // §3.5.2 endpoint is admin-only; a regular member asking would
    // get 403 from the server. Don't even fire the request.
    if (user == null || user.role != 'admin') {
      setState(() => _pendingCount = null);
      return;
    }
    setState(() {
      _pendingCount = _fetchPendingCount(user.familyId);
    });
    await _pendingCount;
  }

  Future<int> _fetchPendingCount(int familyId) async {
    if (AppConfig.mockMode) {
      return MockDataSource.mockJoinRequests().length;
    }
    try {
      final familyService = FamilyService(() {
        final user = context.read<AuthProvider>().currentUser;
        return user?.token ?? '';
      });
      final list = await familyService.fetchJoinRequests(familyId);
      return list.length;
    } catch (_) {
      // Transient blip → badge hides itself rather than painting
      // an error on a row that the user mostly opens for editing
      // profile.
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.role == 'admin';
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
                leading: const _LeadingIcon(
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                ),
                title: l10n.profileFamilyMembersRow,
                subtitle: l10n.profileFamilyMembersSubtitle,
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.inkFaded,
                  size: 20,
                ),
                showSeparator: false,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              HomeCard(
                padding: EdgeInsets.zero,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JoinRequestsScreen(),
                    ),
                  );
                  if (mounted) _refreshPending();
                },
                child: HomeListItem(
                  leading: const _LeadingIcon(
                    icon: Icons.group_add_rounded,
                    color: AppColors.accent,
                  ),
                  title: l10n.profileJoinRequestsRow,
                  subtitle: l10n.profileJoinRequestsAdminOnly,
                  trailing: _pendingCount == null
                      ? const Icon(
                          Icons.chevron_right,
                          color: AppColors.inkFaded,
                          size: 20,
                        )
                      : FutureBuilder<int>(
                          future: _pendingCount,
                          builder: (_, snap) {
                            final n = snap.data ?? 0;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (n > 0)
                                  _PendingBadge(
                                    text: l10n.myHomeJoinRequestsBadge(n),
                                  ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.inkFaded,
                                  size: 20,
                                ),
                              ],
                            );
                          },
                        ),
                  showSeparator: false,
                ),
              ),
            ],
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
                trailing: const Icon(
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
                leading: const _LeadingIcon(
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
                      style: const TextStyle(
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
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
                leading: const _LeadingIcon(
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
                      style: const TextStyle(
                        color: AppColors.inkFaded,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.inkFaded,
                      size: 20,
                    ),
                  ],
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
          style: const TextStyle(color: AppColors.ink),
        ),
        content: Text(
          l10n.profileLogoutConfirmMessage,
          style: const TextStyle(color: AppColors.inkFaded, height: 1.5),
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

/// Bottom-sheet theme picker. Shows each preset as a circle
/// swatch next to its localized name; tapping commits the
/// selection. The currently active preset is marked with a ring.
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            for (final p in AppPalette.presets)
              ListTile(
                leading: _ThemeSwatch(
                  palette: p,
                  selected: p.id == provider.palette.id,
                ),
                title: Text(_paletteDisplayName(p)),
                trailing: p.id == provider.palette.id
                    ? const Icon(
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

String _paletteDisplayName(AppPalette p) {
  switch (p.id) {
    case 'terracotta':
      return 'Terracotta';
    case 'ocean':
      return 'Ocean';
    case 'forest':
      return 'Forest';
    case 'lavender':
      return 'Lavender';
    case 'slate':
      return 'Slate';
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
  final VoidCallback onTap;
  const _ProfileCard({
    required this.name,
    required this.familyName,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.wood, AppColors.woodLight],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.wood.withValues(alpha: 0.35),
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
                          color: Color(0xCCEFE0D0),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          familyName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xCCEFE0D0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

/// Small pill matching the MyHome hub tile badge — kept inline
/// rather than shared so the two pages can diverge visually
/// without one stomping the other's copy.
class _PendingBadge extends StatelessWidget {
  final String text;
  const _PendingBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}