import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_banner.dart';
import '../widgets/join_family_form.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _formKey = GlobalKey<JoinFamilyFormState>();
  bool _submitting = false;
  String? _error;

  Future<void> _confirmAndSubmit(AppLocalizations l10n) async {
    final selection = _formKey.currentState?.getSelection();
    if (selection == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.joinFamilyTitle, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.joinFamilyConfirmMessage,
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      await auth.joinAnotherFamily(
        inviteCode: selection.inviteCode,
        gender: auth.currentUser?.gender ?? 'male',
        relationToMemberId: selection.relationAnchorMemberId,
        relationType: selection.relationType.apiValue,
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      // Preserve the server's error message so the user sees
      // domain-specific failures (`INVALID_RELATION_ANCHOR`,
      // `NO_KNOWN_PARENT`, `SPOUSE_ALREADY_EXISTS`, etc.) instead of
      // an opaque "network error" placeholder.
      setState(() => _error = localizeErrorMessage(e.message, l10n));
    } catch (_) {
      setState(() => _error = localizeErrorMessage(kNetworkErrorSentinel, l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.joinFamilyTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                const SizedBox(height: 16),
              ],
              JoinFamilyForm(key: _formKey),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitting ? null : () => _confirmAndSubmit(l10n),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.registerSubmitJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
