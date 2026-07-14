import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/countries.dart';
import '../l10n/app_localizations.dart';
import '../models/family_member_vm.dart';
import 'error_banner.dart';
import 'phone_input_field.dart';

/// Bundle for the "no invite code — know a member's phone" join flow
/// (docs/api.md §3.5.1). Returned by [RequestJoinFormState.getPayload]
/// when the form is complete; the caller (register_screen) POSTs it
/// via [FamilyService.submitJoinRequest].
class RequestJoinPayload {
  final String name;
  final String phone; // already prefixed with country code
  final String password;
  final String gender; // 'male' / 'female'
  final String targetMemberPhone;
  final RelationType relationType;
  final String? message;

  const RequestJoinPayload({
    required this.name,
    required this.phone,
    required this.password,
    required this.gender,
    required this.targetMemberPhone,
    required this.relationType,
    this.message,
  });
}

/// "No invite code — know a member's phone" form. Pairs with
/// [JoinFamilyForm] inside the register screen's "join family" tab
/// via a sub-toggle (per the BUGS_TO_FIX decision to keep both
/// flows on the same top-level tab rather than splitting into 3
/// tabs). On submit the form POSTs to `/families/join-requests`
/// (§3.5.1) — that endpoint creates the user account + family
/// membership on admin approval (§3.5.3), so the user is not
/// logged in here; [RequestJoinFormState.getPayload] returns the
/// raw fields for the caller to submit.
class RequestJoinForm extends StatefulWidget {
  const RequestJoinForm({super.key});

  @override
  State<RequestJoinForm> createState() => RequestJoinFormState();
}

class RequestJoinFormState extends State<RequestJoinForm> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final targetPhoneCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  Country _selectedCountry = Countries.defaultCountry;
  String _gender = 'male';
  RelationType? _relationType;
  String? _submitError;

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    targetPhoneCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }

  /// Validates and returns the form payload, or null on validation
  /// failure (the inline error is set so the caller doesn't need
  /// to redraw). Use [FamilyService.submitJoinRequest] with the
  /// returned payload.
  RequestJoinPayload? getPayload({required String gender}) {
    final l10n = AppLocalizations.of(context)!;

    String? error;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) error = l10n.registerNicknameRequired;

    final phone = PhoneInputField.fullPhone(_selectedCountry, phoneCtrl);
    if (error == null && phone.isEmpty) error = l10n.phoneRequired;

    final password = passwordCtrl.text;
    if (error == null && password.isEmpty) error = l10n.commonPasswordRequired;
    if (error == null && password.length < 6) {
      error = l10n.commonPasswordTooShort;
    }

    final target = targetPhoneCtrl.text.trim();
    if (error == null && target.isEmpty) {
      error = l10n.requestJoinTargetPhoneRequired;
    }

    if (error == null && _relationType == null) {
      error = l10n.registerRelationAnchorRequired;
    }

    if (error != null) {
      setState(() => _submitError = error);
      return null;
    }

    setState(() => _submitError = null);
    return RequestJoinPayload(
      name: name,
      phone: phone,
      password: password,
      gender: gender,
      targetMemberPhone: target,
      relationType: _relationType!,
      message: messageCtrl.text.trim().isEmpty
          ? null
          : messageCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: l10n.registerNicknameLabel,
            prefixIcon:
                const Icon(Icons.person_outline, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GenderToggle(
                selected: _gender,
                onChanged: (g) => setState(() => _gender = g),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PhoneInputField(
          controller: phoneCtrl,
          selectedCountry: _selectedCountry,
          onCountryChanged: (c) => setState(() => _selectedCountry = c),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.commonPasswordLabel,
            prefixIcon:
                const Icon(Icons.lock_outline, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.requestJoinTargetPhoneLabel,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: targetPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+8613800138000',
            prefixIcon:
                const Icon(Icons.phone_outlined, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.requestJoinTargetPhoneHint,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 16),
        Text(l10n.registerRelationLabel,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500)),
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
        const SizedBox(height: 16),
        TextField(
          controller: messageCtrl,
          maxLength: 200,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.requestJoinMessageLabel,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 8),
          ErrorBanner(
            message: _submitError!,
            onDismiss: () => setState(() => _submitError = null),
          ),
        ],
      ],
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

class _GenderToggle extends StatelessWidget {
  final String selected; // 'male' / 'female'
  final ValueChanged<String> onChanged;

  const _GenderToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _OptionTab(
              label: l10n.registerGenderMale,
              icon: Icons.male,
              selected: selected == 'male',
              onTap: () => onChanged('male'),
            ),
          ),
          Expanded(
            child: _OptionTab(
              label: l10n.registerGenderFemale,
              icon: Icons.female,
              selected: selected == 'female',
              onTap: () => onChanged('female'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}