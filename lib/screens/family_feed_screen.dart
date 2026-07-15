import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/home_widgets.dart';
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
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.familyFeedTitle),
      body: PaperBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
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
                    Icons.timeline_rounded,
                    size: 44,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.familyFeedComingSoon,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.familyFeedComingSoonDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkFaded,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}