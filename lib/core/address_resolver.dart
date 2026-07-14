import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';

/// Best-effort reverse-geocoding for the LocationScreen's member list.
/// Builds a short, human-readable address like "天安门, 东城区,
/// 北京市" from a (lng, lat) pair, in the user's app locale with
/// English as a fallback.
///
/// Concurrent calls coalesce; results are cached per-coords-per-locale
/// so a `notifyListeners` rebuild doesn't fan out N parallel
/// platform-channel calls.
class AddressResolver {
  AddressResolver._();

  static final Geocoding _geocoding = Geocoding();

  static const Duration _timeout = Duration(seconds: 5);

  /// In-memory cache. 4-decimal coords ≈ 11 m precision — plenty
  /// for "this is the school" granularity and stable across the
  /// jitter of fresh fixes vs. cached mock positions. Bounded so a
  /// long session doesn't grow without limit; real-world max is ~5
  /// members × 2 locales = 10 entries.
  static final Map<String, String> _cache = {};
  static const int _kCacheMaxEntries = 200;

  /// In-flight dedup: multiple `_MemberTile` builds scheduling a
  /// reverse-geocode for the same (lng, lat, locale) coalesce into
  /// one platform-channel call. Without this, opening the screen
  /// with 5 members all at once fires 5 parallel calls; the OS
  /// rate-limits these and they each return `[]`.
  static final Map<String, Future<String?>> _inflight = {};

  /// Resolve `(lng, lat)` to a short address in [locale].
  ///
  /// Returns `null` when:
  /// - the platform geocoder has no data for the location at all
  ///   (offline / no provider installed),
  /// - both locale-specific and English lookups returned an empty
  ///   placemark list,
  /// - the device has no Google Play Services (Android) and no iOS
  ///   `CLGeocoder` (web/desktop), which `geocoding: 3.x` surfaces
  ///   as `PlatformException`.
  ///
  /// Synchronous cache-only lookup — returns the cached address if
  /// [resolve] has already resolved this `(lng, lat, locale)`, else
  /// `null`. Lets callers (e.g. `FutureBuilder`'s `initialData`) show
  /// a cached result instantly instead of flashing a loading spinner
  /// for the one microtask [resolve] always takes even on a cache hit.
  static String? peek(double lng, double lat, Locale locale) =>
      _cache[_cacheKey(lng, lat, locale)];

  /// The method is safe to call from `initState` / `didChangeWidget`
  /// etc.; it does its own await internally.
  static Future<String?> resolve(
    double lng,
    double lat,
    Locale locale,
  ) async {
    final key = _cacheKey(lng, lat, locale);
    final cached = _cache[key];
    if (cached != null) return cached;

    final existing = _inflight[key];
    if (existing != null) return existing;
    final completer = Completer<String?>();
    _inflight[key] = completer.future;
    try {
      final result = await _resolveOnce(lng, lat, locale);
      if (result != null) {
        _cache[key] = result;
        _trimCache();
      }
      completer.complete(result);
      return result;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<String?> _resolveOnce(
    double lng,
    double lat,
    Locale locale,
  ) async {
    // Locale strategy: try the device-set locale first (so we
    // honor zh-CN / zh-TW which Android's `Geocoder` distinguishes),
    // then English as the universal fallback.
    String? primary;
    String? english;
    try {
      primary = await _call(lng, lat, locale);
    } catch (_) {
      primary = null;
    }
    if (primary != null) return primary;

    // English fallback — most devices ship en data even when they
    // lack other locales' gazetteers. Skip if primary already was
    // English (would just call the same gazetteer twice).
    if (locale.languageCode != 'en') {
      try {
        english = await _call(lng, lat, const Locale('en'));
      } catch (_) {
        english = null;
      }
    }
    return english;
  }

  static Future<String?> _call(double lng, double lat, Locale locale) async {
    final marks = await _geocoding
        .placemarkFromCoordinates(lat, lng, locale: locale)
        .timeout(_timeout);
    return _formatPlacemarks(marks);
  }

  /// Coords → cache key. 4-decimal precision = ~11 m, which is
  /// fine for "this is the school" granularity and stable across
  /// the jitter of fresh fixes vs. cached mock positions.
  static String _cacheKey(double lng, double lat, Locale locale) {
    final latKey = lat.toStringAsFixed(4);
    final lngKey = lng.toStringAsFixed(4);
    return '$latKey,$lngKey,${locale.toLanguageTag()}';
  }

  static void _trimCache() {
    if (_cache.length <= _kCacheMaxEntries) return;
    final overflow = _cache.length - _kCacheMaxEntries;
    final keys = _cache.keys.take(overflow).toList();
    for (final k in keys) {
      _cache.remove(k);
    }
  }

  /// Build a 3-tier short address from the most-specific reverse
  /// geocoding result. Tries to keep total length ≤ 40 chars so the
  /// `ListTile.subtitle` slot doesn't wrap on narrow phones.
  static String? _formatPlacemarks(List<Placemark> marks) {
    if (marks.isEmpty) return null;
    final m = marks.first;
    final candidates = <String>[
      if ((m.name ?? '').isNotEmpty) m.name!,
      if ((m.subLocality ?? '').isNotEmpty) m.subLocality!,
      if ((m.locality ?? '').isNotEmpty) m.locality!,
      if ((m.administrativeArea ?? '').isNotEmpty) m.administrativeArea!,
    ];
    final seen = <String>{};
    final parts = <String>[];
    for (final c in candidates) {
      if (seen.add(c)) parts.add(c);
      if (parts.length >= 3) break;
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  /// Visible for tests.
  static void clearCacheForTesting() {
    _cache.clear();
    _inflight.clear();
  }
}