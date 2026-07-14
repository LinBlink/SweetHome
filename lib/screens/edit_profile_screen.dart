import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/error_messages.dart';
import '../core/image_mime.dart';
import '../l10n/app_localizations.dart';
import '../models/api_exception.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar_widget.dart';
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
  bool _uploadingAvatar = false;
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

  /// `POST /users/upload/avatar` (docs/api.md §2.3). Picks a single image
  /// from the gallery, lets `image_picker` downscale to ≤512px @ 85% JPEG
  /// quality (the doc's "压缩为 webp 等体积较小的格式" guidance — we trade
  /// webp for the cross-platform-safe JPEG+resize combo `image_picker`
  /// supports out of the box), then uploads the bytes.
  Future<void> _pickAndUploadAvatar(AppLocalizations l10n) async {
    if (_uploadingAvatar) return;
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
    } catch (_) {
      setState(() => _error = l10n.editProfileAvatarFailed);
      return;
    }
    if (picked == null) return; // user cancelled
    setState(() {
      _uploadingAvatar = true;
      _error = null;
    });
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      // Sniff the file's magic bytes first — `XFile.mimeType` is
      // unreliable on Android (frequently `null` for HEIC straight
      // from the camera, some WebPs, or any file surfaced through a
      // third-party picker), and the backend rejects non-`image/*`
      // Content-Types with 400 `FILE_TYPE_ILLEGAL`. Fall back to the
      // picker's claim, then to `image/jpeg` as a last resort — the
      // backend's storage is keyed on the raw bytes, not the MIME,
      // so even an incorrect-but-`image/*` label won't corrupt the
      // avatar URL, just the served Content-Type.
      final contentType =
          detectImageMimeType(bytes) ?? picked.mimeType ?? 'image/jpeg';
      await context.read<AuthProvider>().uploadAvatar(
            bytes: bytes,
            filename: picked.name,
            contentType: contentType,
          );
    } on ApiException catch (e) {
      // Surface the server's message (e.g. 400 FILE_SIZE_ILLEGAL,
      // FILE_TYPE_ILLEGAL) verbatim — those are user-actionable.
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = l10n.editProfileAvatarFailed);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // watch the user so the avatar refreshes immediately after upload
    // (uploadAvatar calls notifyListeners, which re-runs this build).
    final user = context.watch<AuthProvider>().currentUser;
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
                _AvatarPicker(
                  name: user?.name ?? '',
                  avatarUrl: user?.avatarUrl,
                  uploading: _uploadingAvatar,
                  changeLabel: l10n.editProfileChangeAvatar,
                  uploadingLabel: l10n.editProfileAvatarUploading,
                  onTap: () => _pickAndUploadAvatar(l10n),
                ),
                const SizedBox(height: 28),
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

class _AvatarPicker extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool uploading;
  final String changeLabel;
  final String uploadingLabel;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.name,
    required this.avatarUrl,
    required this.uploading,
    required this.changeLabel,
    required this.uploadingLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              AvatarWidget(
                label: name.isEmpty ? '家' : name[0],
                color: AppColors.primary,
                imageUrl: avatarUrl,
                radius: 48,
              ),
              if (uploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: uploading ? null : onTap,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(uploading ? uploadingLabel : changeLabel),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}