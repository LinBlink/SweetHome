import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/countries.dart';
import '../../core/error_messages.dart';
import '../../core/home_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/phone_input_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  Country _selectedCountry = Countries.defaultCountry;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().login(
          PhoneInputField.fullPhone(_selectedCountry, _phoneCtrl),
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PaperBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguagePickerButton(),
                ),
                const SizedBox(height: 24),
                _buildHeader(l10n),
                const SizedBox(height: 44),
                _buildForm(l10n),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 20),
                _buildRegisterLink(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: AppColors.linen, width: 3),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.cottage_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.brandName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.appTagline,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkFaded,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              if (auth.error != null)
                ErrorBanner(
                  message: localizeErrorMessage(auth.error!, l10n),
                  onDismiss: auth.clearError,
                ),
              if (auth.error != null) const SizedBox(height: 16),
              PhoneInputField(
                controller: _phoneCtrl,
                selectedCountry: _selectedCountry,
                onCountryChanged: (c) => setState(() => _selectedCountry = c),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.ink),
                decoration: InputDecoration(
                  labelText: l10n.commonPasswordLabel,
                  labelStyle: const TextStyle(color: AppColors.inkFaded),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.inkFaded,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.commonPasswordRequired;
                  if (v.length < 6) return l10n.commonPasswordTooShort;
                  return null;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        return SizedBox(
          width: double.infinity,
          child: HomePrimaryButton(
            label: auth.isLoading ? '...' : AppLocalizations.of(context)!.loginButton,
            leadingIcon: auth.isLoading
                ? null
                : Icons.login_rounded,
            onPressed: auth.isLoading ? null : _submit,
            fullWidth: true,
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.loginNoAccount,
          style: const TextStyle(color: AppColors.inkFaded),
        ),
        HomeGhostButton(
          label: l10n.loginRegisterNow,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
        ),
      ],
    );
  }
}
