import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../../core/countries.dart';
import '../../core/error_messages.dart';
import '../../core/kinship/kinship_graph.dart';
import '../../l10n/app_localizations.dart';
import '../../models/api_exception.dart';
import '../../models/family_member_vm.dart';
import '../../providers/auth_provider.dart';
import '../../services/family_service.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/join_family_form.dart';
import '../../widgets/phone_input_field.dart';
import '../../widgets/request_join_form.dart';

enum _RegisterMode { create, join }

/// Sub-mode inside `_RegisterMode.join`: use an invite code (current
/// behavior) or apply by a member's phone (API §3.5.1).
enum _JoinSubMode { byCode, byPhone }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  bool _obscurePassword = true;
  _RegisterMode _mode = _RegisterMode.create;
  _JoinSubMode _joinSubMode = _JoinSubMode.byCode;
  Country _selectedCountry = Countries.defaultCountry;
  Gender? _gender = Gender.male;
  final _joinFormKey = GlobalKey<JoinFamilyFormState>();
  final _requestJoinFormKey = GlobalKey<RequestJoinFormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _familyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) return;
    if (_mode == _RegisterMode.join && _joinSubMode == _JoinSubMode.byCode) {
      final selection = _joinFormKey.currentState?.getSelection();
      if (selection == null) return;
      _submitByCode(selection);
    } else if (_mode == _RegisterMode.join &&
        _joinSubMode == _JoinSubMode.byPhone) {
      final payload = _requestJoinFormKey.currentState?.getPayload(
        gender: _gender == Gender.male ? 'male' : 'female',
      );
      if (payload == null) return;
      _submitByPhone(payload);
    } else {
      _submitCreateFamily();
    }
  }

  Future<void> _submitCreateFamily() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<AuthProvider>().register(
            _nameCtrl.text.trim(),
            PhoneInputField.fullPhone(_selectedCountry, _phoneCtrl),
            _passwordCtrl.text,
            gender: _gender == Gender.male ? 'male' : 'female',
            familyName: _familyCtrl.text.trim(),
          );
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      _toastError(e.message);
    } catch (_) {
      _toastError(kNetworkErrorSentinel);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitByCode(JoinFamilySelection join) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<AuthProvider>().register(
            _nameCtrl.text.trim(),
            PhoneInputField.fullPhone(_selectedCountry, _phoneCtrl),
            _passwordCtrl.text,
            gender: _gender == Gender.male ? 'male' : 'female',
            inviteCode: join.inviteCode,
            relationToMemberId: join.relationAnchorMemberId,
            relationType: join.relationType.apiValue,
          );
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      _toastError(e.message);
    } catch (_) {
      _toastError(kNetworkErrorSentinel);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitByPhone(RequestJoinPayload payload) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (AppConfig.mockMode) {
        // Skip the network round-trip; just show the same
        // "submitted, wait for admin approval" dialog the real
        // flow would.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } else {
        await FamilyService.submitJoinRequest(
          name: payload.name,
          phone: payload.phone,
          password: payload.password,
          gender: payload.gender,
          targetMemberPhone: payload.targetMemberPhone,
          relationType: payload.relationType.apiValue,
          message: payload.message,
        );
      }
      if (!mounted) return;
      // Submission is async on the server (admin must approve before
      // the user can log in) — pop the screen and show a confirmation
      // dialog so the user knows to wait for an approval.
      navigator.pop();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l10n.requestJoinSubmittedTitle,
              style: const TextStyle(color: AppColors.textPrimary)),
          content: Text(l10n.requestJoinSubmittedMessage,
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(localizeErrorMessage(e.message, l10n))));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeErrorMessage(kNetworkErrorSentinel, l10n))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toastError(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizeErrorMessage(message, l10n))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.registerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Consumer<AuthProvider>(
            builder: (ctx, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (auth.error != null) ...[
                      ErrorBanner(
                        message: localizeErrorMessage(auth.error!, l10n),
                        onDismiss: auth.clearError,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildField(
                      controller: _nameCtrl,
                      label: l10n.registerNicknameLabel,
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l10n.registerNicknameRequired : null,
                    ),
                    const SizedBox(height: 16),
                    _buildGenderToggle(l10n),
                    const SizedBox(height: 16),
                    PhoneInputField(
                      controller: _phoneCtrl,
                      selectedCountry: _selectedCountry,
                      onCountryChanged: (c) => setState(() => _selectedCountry = c),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.commonPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.commonPasswordRequired;
                        if (v.length < 6) return l10n.commonPasswordTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildModeToggle(l10n),
                    const SizedBox(height: 16),
                    if (_mode == _RegisterMode.create) ...[
                      _buildField(
                        controller: _familyCtrl,
                        label: l10n.registerFamilyNameLabel,
                        icon: Icons.home_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.registerFamilyNameRequired : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.registerFamilyNameHint,
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ] else ...[
                      _buildJoinSubModeToggle(l10n),
                      const SizedBox(height: 16),
                      if (_joinSubMode == _JoinSubMode.byCode)
                        JoinFamilyForm(key: _joinFormKey)
                      else
                        RequestJoinForm(key: _requestJoinFormKey),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (auth.isLoading || _submitting) ? null : _submit,
                        child: (auth.isLoading || _submitting)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(switch (_mode) {
                                _RegisterMode.create => l10n.registerSubmitCreate,
                                _RegisterMode.join => l10n.registerSubmitJoin,
                              }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGenderToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _OptionTab(
            label: l10n.registerGenderMale,
            icon: Icons.male,
            selected: _gender == Gender.male,
            onTap: () => setState(() => _gender = Gender.male),
          ),
          _OptionTab(
            label: l10n.registerGenderFemale,
            icon: Icons.female,
            selected: _gender == Gender.female,
            onTap: () => setState(() => _gender = Gender.female),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _OptionTab(
            label: l10n.registerCreateFamilyTab,
            icon: Icons.add_home_outlined,
            selected: _mode == _RegisterMode.create,
            onTap: () => setState(() => _mode = _RegisterMode.create),
          ),
          _OptionTab(
            label: l10n.registerJoinFamilyTab,
            icon: Icons.group_add_outlined,
            selected: _mode == _RegisterMode.join,
            onTap: () => setState(() => _mode = _RegisterMode.join),
          ),
        ],
      ),
    );
  }

  /// Sub-toggle inside the "join family" mode: invite code vs. know a
  /// member's phone. Both end up calling
  /// `FamilyService.submitJoinRequest` / `register()` but present
  /// different UIs (existing `JoinFamilyForm` for the invite code
  /// path; new `RequestJoinForm` for the phone path).
  Widget _buildJoinSubModeToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _SubToggleChip(
              label: l10n.requestJoinModeByCode,
              icon: Icons.vpn_key_outlined,
              selected: _joinSubMode == _JoinSubMode.byCode,
              onTap: () => setState(() => _joinSubMode = _JoinSubMode.byCode),
            ),
          ),
          Expanded(
            child: _SubToggleChip(
              label: l10n.requestJoinModeByPhone,
              icon: Icons.phone_outlined,
              selected: _joinSubMode == _JoinSubMode.byPhone,
              onTap: () => setState(() => _joinSubMode = _JoinSubMode.byPhone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: validator,
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
    return Expanded(
      child: GestureDetector(
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
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SubToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
