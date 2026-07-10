import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

/// Renders how long until an invite code [expiresAt], picking the largest
/// unit that fits (days → hours → minutes) and falling back to a sub-minute
/// or expired label. All unit strings come from the generated
/// `AppLocalizations` so the wording follows the user's chosen locale.
class InviteExpiry {
  InviteExpiry._();

  static String remaining(BuildContext context, DateTime expiresAt) {
    final l10n = AppLocalizations.of(context)!;
    final delta = expiresAt.difference(DateTime.now());
    if (delta.inSeconds <= 0) return l10n.inviteExpiryExpired;
    if (delta.inDays >= 1) return l10n.inviteExpiryDays(delta.inDays);
    if (delta.inHours >= 1) return l10n.inviteExpiryHours(delta.inHours);
    if (delta.inMinutes >= 1) return l10n.inviteExpiryMinutes(delta.inMinutes);
    return l10n.inviteExpiryLessThanMinute;
  }
}