import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/home_widgets.dart';
import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../services/cache_stats_service.dart';

/// Storage & cache screen, reached from the profile tab's settings
/// section. Shows the on-disk size of each media cache
/// (image/video/audio — each its own `MediaCache` bucket, see that
/// file for why they're separate) plus the avatar cache
/// (`AvatarCache`, dedicated because every member list / chat header
/// / location pin re-renders an avatar image and would re-download
/// without LRU disk caching) plus the locally-cached chat history
/// blob, and lets the user clear any one of them or all at once.
///
/// Replaces the old single confirm-dialog "clear local chat history"
/// row with a fuller breakdown.
class StorageSettingsScreen extends StatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  State<StorageSettingsScreen> createState() => _StorageSettingsScreenState();
}

enum _Category { images, avatars, videos, audio, chatHistory }

class _StorageSettingsScreenState extends State<StorageSettingsScreen> {
  final _stats = const CacheStatsService();
  final Map<_Category, int?> _sizes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _stats.imageCacheSize(),
      _stats.avatarCacheSize(),
      _stats.videoCacheSize(),
      _stats.audioCacheSize(),
      _stats.chatHistorySize(),
    ]);
    if (!mounted) return;
    setState(() {
      _sizes[_Category.images] = results[0];
      _sizes[_Category.avatars] = results[1];
      _sizes[_Category.videos] = results[2];
      _sizes[_Category.audio] = results[3];
      _sizes[_Category.chatHistory] = results[4];
      _loading = false;
    });
  }

  int get _totalKnownBytes => _sizes.values
      .whereType<int>()
      .fold(0, (sum, v) => sum + v);

  String _label(AppLocalizations l10n, _Category c) {
    switch (c) {
      case _Category.images:
        return l10n.storageImageCache;
      case _Category.avatars:
        return l10n.storageAvatarCache;
      case _Category.videos:
        return l10n.storageVideoCache;
      case _Category.audio:
        return l10n.storageAudioCache;
      case _Category.chatHistory:
        return l10n.storageChatHistory;
    }
  }

  String _sizeText(AppLocalizations l10n, _Category c) {
    final bytes = _sizes[c];
    if (bytes == null) return l10n.storageSizeUnknown;
    return formatCacheSize(bytes);
  }

  Future<void> _clearCategory(_Category c) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          c == _Category.chatHistory
              ? l10n.profileClearLocalChatConfirmTitle
              : l10n.storageClearMediaConfirmTitle(_label(l10n, c)),
          style: TextStyle(color: AppColors.ink),
        ),
        content: Text(
          c == _Category.chatHistory
              ? l10n.profileClearLocalChatConfirmBody
              : l10n.storageClearMediaConfirmBody,
          style: TextStyle(color: AppColors.inkFaded, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.storageClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    switch (c) {
      case _Category.images:
        await _stats.clearImages();
        break;
      case _Category.avatars:
        await _stats.clearAvatars();
        break;
      case _Category.videos:
        await _stats.clearVideos();
        break;
      case _Category.audio:
        await _stats.clearAudio();
        break;
      case _Category.chatHistory:
        await context.read<ChatProvider>().clearLocalChatHistory();
        break;
    }
    if (!mounted) return;
    setState(() => _sizes[c] = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          c == _Category.chatHistory
              ? l10n.profileClearLocalChatSuccess
              : l10n.storageClearSuccess,
        ),
      ),
    );
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.storageClearAllConfirmTitle,
          style: TextStyle(color: AppColors.ink),
        ),
        content: Text(
          l10n.storageClearAllConfirmBody,
          style: TextStyle(color: AppColors.inkFaded, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.storageClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await Future.wait([
      _stats.clearAllMedia(),
      context.read<ChatProvider>().clearLocalChatHistory(),
    ]);
    if (!mounted) return;
    setState(() {
      _sizes[_Category.images] = 0;
      _sizes[_Category.avatars] = 0;
      _sizes[_Category.videos] = 0;
      _sizes[_Category.audio] = 0;
      _sizes[_Category.chatHistory] = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.storageClearSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HomeAppBar(title: l10n.storageScreenTitle),
      body: PaperBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  HomeCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.storageTotalLabel(
                            formatCacheSize(_totalKnownBytes),
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  HomeCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _categoryRow(l10n, _Category.images,
                            Icons.image_outlined, AppColors.sage),
                        _categoryRow(l10n, _Category.avatars,
                            Icons.account_circle_outlined, AppColors.primaryLight),
                        _categoryRow(l10n, _Category.videos,
                            Icons.videocam_outlined, AppColors.accent),
                        _categoryRow(l10n, _Category.audio,
                            Icons.graphic_eq_rounded, AppColors.primary,
                            showSeparator: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HomeCard(
                    padding: EdgeInsets.zero,
                    child: _categoryRow(
                      l10n,
                      _Category.chatHistory,
                      Icons.chat_bubble_outline_rounded,
                      AppColors.primaryDark,
                      showSeparator: false,
                    ),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: _clearAll,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.6),
                        width: 1.4,
                      ),
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      l10n.storageClearAll,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _categoryRow(
    AppLocalizations l10n,
    _Category c,
    IconData icon,
    Color color, {
    bool showSeparator = true,
  }) {
    return HomeListItem(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 20),
      ),
      title: _label(l10n, c),
      subtitle: _sizeText(l10n, c),
      trailing: IconButton(
        tooltip: l10n.storageClear,
        icon: Icon(Icons.delete_outline_rounded,
            color: AppColors.inkFaded, size: 20),
        onPressed: () => _clearCategory(c),
      ),
      showSeparator: showSeparator,
    );
  }
}
