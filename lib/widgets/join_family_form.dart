import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/family_member_vm.dart';
import '../providers/auth_provider.dart';
import 'error_banner.dart';

class JoinFamilySelection {
  final String inviteCode;
  final int relationAnchorMemberId;
  final RelationType relationType;
  const JoinFamilySelection({
    required this.inviteCode,
    required this.relationAnchorMemberId,
    required this.relationType,
  });
}

/// Shared "invite code → family preview → relation picker" UI, used by both
/// `register_screen.dart`'s join-mode and `join_family_screen.dart` (joining
/// a different family while already logged in).
class JoinFamilyForm extends StatefulWidget {
  const JoinFamilyForm({super.key});

  @override
  State<JoinFamilyForm> createState() => JoinFamilyFormState();
}

class JoinFamilyFormState extends State<JoinFamilyForm> {
  final inviteCtrl = TextEditingController();
  bool _lookingUp = false;
  String? _lookupError;
  FamilyPreview? _familyPreview;
  int? _relationAnchorMemberId;
  RelationType? _relationType;

  @override
  void dispose() {
    inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupFamily() async {
    final code = inviteCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _lookingUp = true;
      _lookupError = null;
    });
    try {
      final preview = await context.read<AuthProvider>().lookupFamily(code);
      setState(() {
        _familyPreview = preview;
        _relationAnchorMemberId = null;
        _relationType = null;
      });
    } catch (_) {
      setState(() {
        _familyPreview = null;
        _lookupError = AppLocalizations.of(context)!.registerFindFamilyFailed;
      });
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  /// Validates the invite code + relation selection, surfacing an inline
  /// error and returning null if incomplete.
  JoinFamilySelection? getSelection() {
    final l10n = AppLocalizations.of(context)!;
    final code = inviteCtrl.text.trim();
    if (code.isEmpty || code.length < 4) {
      setState(() => _lookupError = l10n.registerInviteCodeInvalid);
      return null;
    }
    if (_relationAnchorMemberId == null || _relationType == null) {
      setState(() => _lookupError = l10n.registerRelationAnchorRequired);
      return null;
    }
    return JoinFamilySelection(
      inviteCode: code,
      relationAnchorMemberId: _relationAnchorMemberId!,
      relationType: _relationType!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: inviteCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.registerInviteCodeLabel,
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _lookingUp ? null : _lookupFamily,
                child: _lookingUp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.registerFindFamilyButton),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(l10n.registerInviteCodeHint,
            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
        if (_lookupError != null) ...[
          const SizedBox(height: 8),
          ErrorBanner(
            message: _lookupError!,
            onDismiss: () => setState(() => _lookupError = null),
          ),
        ],
        if (_familyPreview != null) ...[
          const SizedBox(height: 16),
          _buildRelationPicker(l10n, _familyPreview!),
        ],
      ],
    );
  }

  Widget _buildRelationPicker(AppLocalizations l10n, FamilyPreview preview) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.familyName,
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: _relationAnchorMemberId,
            onChanged: (v) => setState(() => _relationAnchorMemberId = v),
            child: Column(
              children: preview.members
                  .map((m) => RadioListTile<int>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.name),
                        value: m.memberId,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.registerRelationLabel,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _relationChip(l10n.registerRelationChild, RelationType.childOf),
              _relationChip(l10n.registerRelationParent, RelationType.parentOf),
              _relationChip(l10n.registerRelationSpouse, RelationType.spouseOf),
              _relationChip(l10n.registerRelationSibling, RelationType.siblingOf),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relationChip(String label, RelationType type) {
    return ChoiceChip(
      label: Text(label),
      selected: _relationType == type,
      onSelected: (_) => setState(() => _relationType = type),
    );
  }
}
