import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/location_provider.dart';
import 'location_hub_screen.dart';

/// "我的家" tab — the **sub-app entry hub** for the bottom nav.
/// Each tile here opens a self-contained sub-app (currently just
/// "Real-time Location", which itself contains live map + history
/// + geofences + alerts). Future feature areas add another tile.
///
/// Admin-only work (e.g. join-request approvals) lives on the
/// Profile tab now — the MyHome hub is strictly a launcher.
class MyHomeScreen extends StatelessWidget {
  const MyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.myHomeTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _HubTile(
            icon: Icons.location_on_outlined,
            title: l10n.locationHubTitle,
            subtitle: l10n.locationHubSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                // Navigator.push inserts the new route as a sibling
                // of MyHomeScreen's own provider scope, not a
                // descendant of it, so the app-scoped LocationProvider
                // (provided in main.dart) has to be re-provided
                // explicitly for the live-map screen inside the
                // sub-app hub — same pattern as the ChatProvider
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
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}