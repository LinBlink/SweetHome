import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Placeholder for the "家庭动态" tab. Per BUGS_TO_FIX.md, the backend
/// for this feature isn't built yet, so this is a "coming soon" stub.
/// Kept as a real screen (not just a hardcoded icon) so the rest of
/// the bottom-nav structure stays uniform — when the backend lands
/// only the body needs to swap.
class FamilyFeedScreen extends StatelessWidget {
  const FamilyFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.familyFeedTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline_outlined,
                size: 72,
                color: AppColors.primaryLight.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.familyFeedComingSoon,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.familyFeedComingSoonDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}