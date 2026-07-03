import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/error_messages.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_banner.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: context.read<AuthProvider>().currentUser?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().updateProfile(_nameCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _error = localizeErrorMessage(kNetworkErrorSentinel, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.editProfileNicknameLabel,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.registerNicknameRequired : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : () => _save(l10n),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.editProfileSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
