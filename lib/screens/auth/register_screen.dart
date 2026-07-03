import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/countries.dart';
import '../../core/error_messages.dart';
import '../../core/kinship/kinship_graph.dart';
import '../../l10n/app_localizations.dart';
import '../../models/family_member_vm.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/join_family_form.dart';
import '../../widgets/phone_input_field.dart';

enum _RegisterMode { create, join }

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
  Country _selectedCountry = Countries.defaultCountry;
  Gender? _gender = Gender.male;
  final _joinFormKey = GlobalKey<JoinFamilyFormState>();

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
    JoinFamilySelection? join;
    if (_mode == _RegisterMode.join) {
      join = _joinFormKey.currentState?.getSelection();
      if (join == null) return;
    }
    await context.read<AuthProvider>().register(
          _nameCtrl.text.trim(),
          PhoneInputField.fullPhone(_selectedCountry, _phoneCtrl),
          _passwordCtrl.text,
          gender: _gender == Gender.male ? 'male' : 'female',
          familyName: _mode == _RegisterMode.create ? _familyCtrl.text.trim() : null,
          inviteCode: join?.inviteCode,
          relationToMemberId: join?.relationAnchorMemberId,
          relationType: join?.relationType.apiValue,
        );
    if (mounted && context.read<AuthProvider>().isAuthenticated) {
      Navigator.pop(context);
    }
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
                      JoinFamilyForm(key: _joinFormKey),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
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
