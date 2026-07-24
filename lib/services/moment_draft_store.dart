import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists a single in-progress moment draft (caption + media
/// references) so backing out of `PublishMomentScreen` doesn't throw
/// it away — restored the next time the composer opens. One slot per
/// user (keyed by userId); saving overwrites whatever was there
/// before, there's no multi-draft history.
///
/// Media can't be stored as raw bytes here (SharedPreferences is for
/// small string values, and a photo/video draft can be several MB) —
/// only the local file path plus, if the upload had already
/// succeeded, the resulting `remoteUrl`. `PublishMomentScreen` is
/// responsible for checking the local file still exists before
/// treating a restored entry as previewable/re-uploadable.
class MomentDraftStore {
  static String _key(int userId) => 'moment_draft_v1_$userId';

  static Future<void> save(int userId, MomentDraftSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(snapshot.toJson()));
  }

  static Future<MomentDraftSnapshot?> load(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null) return null;
    try {
      return MomentDraftSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }
}

class MomentDraftSnapshot {
  final String content;
  final List<MomentDraftMediaSnapshot> media;

  /// Whether the composer was set to publish publicly when the draft
  /// was saved. Defaulted to `false` for drafts saved by older app
  /// versions that didn't have the toggle; the public-mode flag is a
  /// forward-compatible optional field, missing on the wire just
  /// means "family only" — same as the §7.1 server default.
  final bool isPublic;

  const MomentDraftSnapshot({
    required this.content,
    required this.media,
    this.isPublic = false,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'media': media.map((m) => m.toJson()).toList(),
        'isPublic': isPublic,
      };

  factory MomentDraftSnapshot.fromJson(Map<String, dynamic> json) {
    return MomentDraftSnapshot(
      content: json['content'] as String? ?? '',
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((e) =>
              MomentDraftMediaSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }
}

/// [kind] is the wire string ('photo'/'video'/'audio') rather than
/// `MomentDraftKind` directly so this file has no dependency on
/// `moment_provider.dart` — it's a pure storage shape.
class MomentDraftMediaSnapshot {
  final String kind;
  final String? localPath;
  final String? remoteUrl;
  final int? durationSec;

  const MomentDraftMediaSnapshot({
    required this.kind,
    this.localPath,
    this.remoteUrl,
    this.durationSec,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (localPath != null) 'localPath': localPath,
        if (remoteUrl != null) 'remoteUrl': remoteUrl,
        if (durationSec != null) 'durationSec': durationSec,
      };

  factory MomentDraftMediaSnapshot.fromJson(Map<String, dynamic> json) {
    return MomentDraftMediaSnapshot(
      kind: json['kind'] as String,
      localPath: json['localPath'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      durationSec: json['durationSec'] as int?,
    );
  }
}
