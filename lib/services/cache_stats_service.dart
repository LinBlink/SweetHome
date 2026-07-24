import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'avatar_cache.dart';
import 'chat_local_cache.dart';
import 'media_cache.dart';

/// Reads and clears the on-disk footprint of the app's caches for the
/// storage settings screen. Each [MediaCache] manager stores its files
/// under `<temporary dir>/<cacheKey>` (see `flutter_cache_manager`'s
/// `IOFileSystem`) — not exposed by the package itself, so sizing is
/// done by walking that folder directly rather than through any
/// `CacheManager` API.
///
/// Not meaningful on web: there's no filesystem to walk (media caches
/// there live in IndexedDB via `flutter_cache_manager`'s web backend),
/// so [imageCacheSize]/[videoCacheSize]/[audioCacheSize]/
/// [avatarCacheSize] report `null` there. `emptyCache()` itself still
/// works on web, so clearing is still offered — it just can't be
/// sized first.
class CacheStatsService {
  const CacheStatsService();

  Future<int?> imageCacheSize() => _directorySize(MediaCache.images.config.cacheKey);
  Future<int?> videoCacheSize() => _directorySize(MediaCache.videos.config.cacheKey);
  Future<int?> audioCacheSize() => _directorySize(MediaCache.audio.config.cacheKey);
  Future<int?> avatarCacheSize() => _directorySize(AvatarCache.cacheDirectoryKey);

  /// Size of the locally-persisted chat history blob.
  Future<int> chatHistorySize() => ChatLocalCache().sizeBytes();

  Future<int?> _directorySize(String cacheKey) async {
    if (kIsWeb) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(p.join(tempDir.path, cacheKey));
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearImages() => MediaCache.images.emptyCache();
  Future<void> clearVideos() => MediaCache.videos.emptyCache();
  Future<void> clearAudio() => MediaCache.audio.emptyCache();
  Future<void> clearAvatars() => AvatarCache.empty();

  Future<void> clearAllMedia() async {
    // Image / video / audio caches and the avatar cache live in
    // independent `CacheManager` directories on disk. The storage
    // settings' "Clear all" button triggers this so the user gets one
    // shot at resetting all four. Chat history is cleared separately
    // (and intentionally not bundled with media clears, since the
    // dialog titles differ and chat-history clear has its own UX
    // confirmation copy — see `ChatProvider.clearLocalChatHistory`).
    await Future.wait([
      clearImages(),
      clearVideos(),
      clearAudio(),
      clearAvatars(),
    ]);
  }
}

/// Human-readable size, e.g. `1.2 MB` / `340 KB` / `0 B`. Binary
/// (1024-based) units to match what Android/iOS storage settings show.
String formatCacheSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final decimals = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}
