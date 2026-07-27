import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A small versioned JSON blob on disk, for the "render last known data
/// instantly, then quietly check the server" pattern.
///
/// One store per kind of data ([namespace]), one blob per owner
/// ([scope] — normally the user id, since every cached payload here is
/// something the server answers differently per account). Keeping the
/// scope in the key is what stops user B from seeing user A's family
/// after a logout/login on a shared device.
///
/// Everything fails soft. A blob that is missing, truncated, written by
/// a different app version, or otherwise unreadable reads back as
/// `null`, which callers already have to handle — it is the same state
/// as "nothing cached yet". A cache that throws would be worse than no
/// cache at all: it would break the very screens it exists to speed up.
///
/// Deliberately not a general key-value store: payloads are whole
/// screens' worth of data, written after a successful fetch and read
/// once at start-up, so per-item granularity would buy nothing and cost
/// a lot of `SharedPreferences` round-trips.
class LocalCacheStore {
  /// Identifies the kind of data. Becomes part of the storage key.
  final String namespace;

  /// Bump when the shape of what you store changes in a way older or
  /// newer app versions cannot read. A blob whose version does not
  /// match is dropped rather than parsed.
  final int schemaVersion;

  const LocalCacheStore(this.namespace, {this.schemaVersion = 1});

  String _key(String scope) => 'cache_v2_${namespace}_$scope';

  /// The decoded payload, or `null` for any flavour of miss.
  Future<Object?> read(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(scope));
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (envelope['v'] != schemaVersion) {
        // Written by another version of this app. Its shape is not our
        // shape; drop it instead of guessing.
        await prefs.remove(_key(scope));
        return null;
      }
      return envelope['data'];
    } catch (_) {
      await prefs.remove(_key(scope));
      return null;
    }
  }

  /// When [scope]'s payload was last written, or `null` if there is
  /// none. Callers that want a "cache is too old to show at all" rule
  /// impose it themselves — this store keeps data forever, because for
  /// a family app a stale contact list is still a far better first
  /// paint than a spinner.
  Future<DateTime?> writtenAt(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(scope));
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      return DateTime.tryParse(envelope['at'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String scope, Object? data) async {
    final prefs = await SharedPreferences.getInstance();
    final envelope = jsonEncode({
      'v': schemaVersion,
      'at': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    });
    await prefs.setString(_key(scope), envelope);
  }

  Future<void> clear(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(scope));
  }

  /// Drops every scope of this namespace — the "clear cached data"
  /// action, which must not leave one stale user's blob behind.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'cache_v2_${namespace}_';
    for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await prefs.remove(key);
    }
  }

  /// Total UTF-8 size of every scope of this namespace, for the storage
  /// settings screen.
  Future<int> sizeBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'cache_v2_${namespace}_';
    var total = 0;
    for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      final raw = prefs.getString(key);
      if (raw != null) total += utf8.encode(raw).length;
    }
    return total;
  }
}
