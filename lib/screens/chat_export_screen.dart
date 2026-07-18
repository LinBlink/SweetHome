import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/home_widgets.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/chat_export_service.dart';

/// Exports the locally-cached chat history (`ChatLocalCache`) as a
/// plain-text transcript. Reached from the profile tab's settings
/// section. No share-sheet dependency: on native platforms the
/// transcript is also written to a file in the app's documents
/// directory (path shown so the user can find it in a file manager),
/// and "copy" always works everywhere including web.
class ChatExportScreen extends StatefulWidget {
  const ChatExportScreen({super.key});

  @override
  State<ChatExportScreen> createState() => _ChatExportScreenState();
}

class _ChatExportScreenState extends State<ChatExportScreen> {
  final _service = const ChatExportService();
  ChatExportResult? _result;
  String? _savedPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    final result = await _service.buildTranscript(
      currentUserId: userId,
      meLabel: l10n.profileMe,
      imageLabel: l10n.chatMessageTypeImage,
      voiceLabel: l10n.chatMessageTypeVoice,
    );
    String? savedPath;
    if (result != null && !kIsWeb) {
      savedPath = await _saveToFile(result.text);
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _savedPath = savedPath;
      _loading = false;
    });
  }

  Future<String?> _saveToFile(String text) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final name = 'sweethome_chat_export_'
          '${now.year}${two(now.month)}${two(now.day)}_'
          '${two(now.hour)}${two(now.minute)}.txt';
      final file = File('${dir.path}/$name');
      await file.writeAsString(text);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _copyAll() async {
    final l10n = AppLocalizations.of(context)!;
    final result = _result;
    if (result == null) return;
    await Clipboard.setData(ClipboardData(text: result.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.chatExportCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.chatExportTitle),
      body: PaperBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _result == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 56,
                            color: AppColors.primaryLight.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.chatExportEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.chatExportSummary(
                                _result!.conversationCount,
                                _result!.messageCount,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_savedPath != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                l10n.chatExportSavedTo(_savedPath!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            HomePrimaryButton(
                              label: l10n.chatExportCopy,
                              leadingIcon: Icons.copy_all_rounded,
                              onPressed: _copyAll,
                              fullWidth: true,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _result!.text,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.ink,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
