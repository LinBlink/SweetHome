import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/countries.dart';
import '../../core/error_messages.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: LanguagePickerButton(),
              ),
              const SizedBox(height: 16),
              _buildHeader(l10n),
              const SizedBox(height: 48),
              _buildForm(l10n),
              const SizedBox(height: 32),
              _buildLoginButton(),
              const SizedBox(height: 20),
              _buildRegisterLink(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '家',
              style: TextStyle(
                fontSize: 44,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.brandName,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.appTagline,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            letterSpacing: 1,
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
                decoration: InputDecoration(
                  labelText: l10n.commonPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                : Text(AppLocalizations.of(context)!.loginButton),
          ),
        );
      },
    );
  }

  Widget _buildRegisterLink(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.loginNoAccount, style: const TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Text(l10n.loginRegisterNow, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
