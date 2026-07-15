import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/home_widgets.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import 'family_tree_screen.dart';
import 'location_hub_screen.dart';

/// "鎴戠殑锟? tab 锟?the **sub-app entry hub** for the bottom nav.
/// Each tile here opens a self-contained sub-app.
///
/// The hub is the home's "front door" 锟?the visual tone is set
/// here. A warm welcome header (greeting + family name), then
/// paper-craft tiles for each sub-app.
class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(
        title: l10n.myHomeTitle,
        subtitle: l10n.appTagline,
      ),
      body: PaperBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _WelcomeCard(),
            const SizedBox(height: 20),
            HomeSectionHeader(
              title: l10n.myHomeSectionFamilyTitle,
              accentIcon: Icons.cottage_rounded,
            ),
            _HubTile(
              icon: Icons.account_tree_outlined,
              title: l10n.myHomeFamilyTreeEntry,
              subtitle: l10n.myHomeFamilyTreeDesc,
              color: AppColors.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FamilyTreeScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _HubTile(
              icon: Icons.location_on_outlined,
              title: l10n.locationHubTitle,
              subtitle: l10n.locationHubSubtitle,
              color: AppColors.sage,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  // Navigator.push inserts the new route as a sibling
                  // of MyHomeScreen's own provider scope, not a
                  // descendant of it, so the app-scoped LocationProvider
                  // (provided in main.dart) has to be re-provided
                  // explicitly for the live-map screen inside the
                  // sub-app hub 锟?same pattern as the ChatProvider
                  // re-wiring used elsewhere in this app.
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<LocationProvider>(),
                    child: const LocationHubScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A "welcome mat" at the top of the hub 锟?a card with a soft
/// linen background, the family name in serif-feel, and a tiny
/// "锟? stamp accent. Sets the home-craft tone before the user
/// hits the feature list.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    return HomeCard(
      color: AppColors.linen,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.cottage_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting(l10n, auth.currentUser?.name),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.currentUser?.familyName ?? l10n.brandName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.myHomeWelcomeTagline,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkFaded,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(AppLocalizations l10n, String? name) {
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.greetingLateNight;
    if (hour < 11) return l10n.greetingMorning;
    if (hour < 14) return l10n.greetingNoon;
    if (hour < 18) return l10n.greetingAfternoon;
    if (hour < 22) return l10n.greetingEvening;
    return l10n.greetingLateNight;
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkFaded,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: color,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

