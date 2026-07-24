import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// On-disk avatar cache. Mirrors the structure of [MediaCache] (one
/// `CacheManager` keyed by a stable namespace string so its folder is
/// self-contained under `<temporary dir>/<cacheKey>`) so the storage
/// settings screen (`CacheStatsService`) can size and clear the avatar
/// cache independently of the photo / video / audio caches.
///
/// Avatars are tiny (a 40×40 WebP is well under 4 KB) but every member
/// list, chat header, comment row and location-pin call renders one,
/// so without an LRU the [Image.network] cache gives us a fresh GET
/// and re-decode every time the user navigates between two screens
/// (each avatar image goes through a re-decoded `ui.Image` and gets
/// fired off without persistence — see [AvatarWidget] for the prior
/// raw-loader story). Routing through [CachedNetworkImage] with this
/// dedicated manager replaces per-screen-decode cost with a single
/// disk-backed fetch and a single in-memory decode per avatar URL.
///
/// Web: `flutter_cache_manager`'s web backend is IndexedDB, but we
/// still short-circuit to `Image.network` / `HtmlElementView` because
/// the user's avatar URLs come from Cloudflare R2 and the dev-host
/// (e.g. `http://192.168.*:*`) isn't whitelisted in the bucket's CORS
/// config (see `_web_image_web.dart`). On web the browser HTTP cache
/// already de-dupes by URL, which is what we actually want here — so
/// no `CacheManager` is needed on that platform.
class AvatarCache {
  AvatarCache._();

  static const String _cacheKey = 'sweethome_avatar_cache';

  /// Lower than the per-image cache (200KB avatars are typical for the
  /// 64px display circle; 2× that lets a fresh login keep a few
  /// refreshed avatars without re-fetching).
  static const int _maxEntries = 200;

  static final CacheManager _manager = CacheManager(
    Config(
      _cacheKey,
      maxNrOfCacheObjects: _maxEntries,
      stalePeriod: const Duration(days: 30),
    ),
  );

  /// The single shared [CacheManager] backing the avatar cache. Pass
  /// to `CachedNetworkImage`'s `cacheManager` parameter so the widget
  /// reads/writes through this on every render.
  static CacheManager get manager => _manager;

  /// Empty the entire avatar cache. Used by the storage settings
  /// screen's "Clear cache" buttons (per-category + clear-all).
  static Future<void> empty() => _manager.emptyCache();

  /// `true` when running on a platform where flutter_cache_manager
  /// has a real backend (mobile/desktop). Web returns `false` so
  /// callers can branch — the storage settings screen reports
  /// size as "unknown" on web (same as [MediaCache]), and the
  /// clear buttons there still work but are visual no-ops.
  static bool get isAvailable => !kIsWeb;

  /// Stable key used by [CacheStatsService] to walk the on-disk
  /// folder directly (flutter_cache_manager does not expose a
  /// per-instance directory API). Mirrors `MediaCache.videos.config.cacheKey`
  /// — see that file for why the storage size is done by directory
  /// walk rather than through `CacheManager`'s public surface.
  static String get cacheDirectoryKey => _cacheKey;
}
