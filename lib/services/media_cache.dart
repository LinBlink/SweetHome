import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Three separate on-disk caches — one per media kind — instead of
/// everything sharing `flutter_cache_manager`'s single unnamed
/// `DefaultCacheManager()`. A distinct `Config.cacheKey` gives each
/// its own storage folder/index, which is what lets the storage
/// settings screen report and clear "image cache" / "video cache" /
/// "audio cache" independently rather than as one lump sum.
///
/// Used by [MomentCard]'s image tiles, `_cachedVideoController`, and
/// the audio tile — anywhere a moment's media is fetched from the
/// network and cached locally.
class MediaCache {
  MediaCache._();

  static final CacheManager images = CacheManager(
    Config('sweethome_image_cache', maxNrOfCacheObjects: 500),
  );

  static final CacheManager videos = CacheManager(
    Config('sweethome_video_cache', maxNrOfCacheObjects: 200),
  );

  static final CacheManager audio = CacheManager(
    Config('sweethome_audio_cache', maxNrOfCacheObjects: 200),
  );

  static List<CacheManager> get all => [images, videos, audio];
}
