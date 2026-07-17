import 'dart:typed_data';

import '../core/time/backend_time.dart';

/// Family-feed moment — docs/api.md §7. The `media` payload can
/// contain any mix of images/videos/audios; rendering branches on
/// each item's [MomentMedia.type].
///
/// `createdAt` is the server's wall-clock time of the post
/// (UTC+8, no TZ suffix — same shape as the §6 timestamp contract).
/// Client renders it via `AppTimeFormatter` after `.toLocal()`,
/// matching the §4 message-bubble pattern.
class Moment {
  final int id;
  final int userId;
  final String username;
  final String? userAvatarUrl;
  final DateTime createdAt;

  /// Display-only text body. May be `null` if the moment is media-only
  /// (a photo dump with no caption) — see §7.1 business logic
  /// (content + media must not both be empty, but media-only is valid).
  final String? content;
  final List<MomentMedia> media;

  const Moment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.createdAt,
    required this.content,
    required this.media,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['mediaFiles'] as List<dynamic>? ??
        json['media'] as List<dynamic>? ??
        const [];
    return Moment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      createdAt: parseBackendTime(json['createdAt'] as String),
      content:
          (json['content'] as String?)?.isEmpty == true ? null : json['content'] as String?,
      media: mediaRaw
          .map((e) => MomentMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Round-trips through the same shape [Moment.fromJson] reads, so the
  /// local feed cache (`MomentProvider`) can serialize/deserialize with
  /// the same parser instead of maintaining a second cache-only schema.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'content': content,
      'mediaFiles': media.map((m) => m.toJson()).toList(),
    };
  }
}

/// One media file attached to a moment — docs/api.md §7.1/§7.2.
/// `type` is one of `image` / `video` / `audio` (the three values
/// the §7.1 `media[].type` whitelist permits; `INSTRUMENT_*` is
/// reserved server-side per §7.8).
class MomentMedia {
  final MomentMediaType type;
  final String url;
  final DateTime? createdAt;

  const MomentMedia({
    required this.type,
    required this.url,
    this.createdAt,
  });

  factory MomentMedia.fromJson(Map<String, dynamic> json) {
    return MomentMedia(
      type: _parseType(json['type'] as String?),
      url: json['content'] as String,
      createdAt: json['createdAt'] != null
          ? parseBackendTime(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _typeToWire(type),
      'content': url,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static String _typeToWire(MomentMediaType t) {
    switch (t) {
      case MomentMediaType.image:
        return 'image';
      case MomentMediaType.video:
        return 'video';
      case MomentMediaType.audio:
        return 'audio';
    }
  }

  static MomentMediaType _parseType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'image':
        return MomentMediaType.image;
      case 'video':
        return MomentMediaType.video;
      case 'audio':
        return MomentMediaType.audio;
      default:
        // Server-side whitelist is enforced (see §7.8
        // `INVALID_MOMENT_MEDIA_TYPE`); an unknown value at this
        // layer means the spec was extended post-hand-off. Default
        // to image so the row still renders something rather than
        // throwing on parse.
        return MomentMediaType.image;
    }
  }
}

enum MomentMediaType { image, video, audio }

/// One row from `GET /moment/liker/{id}/like-detail` (§7.7).
/// Aggregated per-liker, with a running count so the row can show
/// "张美玲 x10" instead of just "张美玲" when one user has clicked
/// the button more than once.
class LikerEntry {
  final int userId;
  final String username;
  final String? userAvatarUrl;
  final int likeCount;

  const LikerEntry({
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.likeCount,
  });

  factory LikerEntry.fromJson(Map<String, dynamic> json) {
    return LikerEntry(
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      likeCount: json['likeCount'] as int? ?? 1,
    );
  }
}

/// Aggregated §7.7 envelope. `totalLikes` is the canonical big
/// number rendered next to the thumb button; `likers` powers the
/// "who liked this" bottom sheet.
class MomentLikeDetail {
  final int totalLikes;
  final List<LikerEntry> likers;

  const MomentLikeDetail({
    required this.totalLikes,
    required this.likers,
  });

  factory MomentLikeDetail.fromJson(Map<String, dynamic> json) {
    final list = (json['likers'] as List<dynamic>? ?? const [])
        .map((e) => LikerEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return MomentLikeDetail(
      totalLikes: json['totalLikes'] as int? ?? 0,
      likers: list,
    );
  }
}

/// Page wrapper for `GET /moment/myfamily` (§7.2). Mirrors the
/// cursor-paginated shape used by §4.3 (cursor -> next page id;
/// null cursor means "no more pages").
class MomentPage {
  final List<Moment> moments;
  final int total;

  const MomentPage({required this.moments, required this.total});
}

/// One row from `GET /moment/comment/{momentId}` (§7.9). Server
/// returns oldest-first (`created_at` ascending) so the detail
/// screen just renders in received order. Per §7.10 only the
/// comment author can delete (not the moment's publisher); the
/// delete UI is gated on [userId] == current user.
class MomentComment {
  final int id;
  final int userId;
  final String username;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;

  const MomentComment({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory MomentComment.fromJson(Map<String, dynamic> json) {
    return MomentComment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String? ?? '',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: parseBackendTime(json['createdAt'] as String),
    );
  }
}

/// A single piece of media the user picked in the publish composer,
/// *before* it's been uploaded. Holds the local file reference plus
/// the bytes that the `UploadService` will POST.
class MomentMediaDraft {
  final MomentMediaType type;
  final Uint8ListHolder bytes;
  final String filename;

  /// Localized user-facing label (e.g. "Photo", "Video 00:42"),
  /// derived when the draft is created and shown on the publish UI
  /// so the user can identify items. Not part of the wire payload.
  final String label;

  /// Optional pre-computed duration for video / audio drafts, in
  /// seconds. Used to render the play-time label (e.g. "0:42") and
  /// to cap the audio recorder preview without re-decoding.
  final int? durationSec;

  const MomentMediaDraft({
    required this.type,
    required this.bytes,
    required this.filename,
    required this.label,
    this.durationSec,
  });
}

/// Wrapper that holds mutable bytes (`Uint8List` is the only Dart
/// primitive that can back a `BytesBuilder`-style accumulator, but
/// `record`-package streamed audio chunks are easier to accumulate
/// via a sink than via `+=` on `Uint8List`). Holding a `final` slot
/// lets the draft class stay immutable while the recorder itself
/// can still stream into the buffer behind the holder.
class Uint8ListHolder {
  Uint8List value;
  Uint8ListHolder(this.value);
}

/// Tiny import alias so callers don't need to import `dart:typed_data`
/// just to declare the holder. Re-export [Uint8ListHolder] (defined
/// above) and a type alias so the publish composer and recorder
/// can stay platform-neutral.
typedef MediaBytes = Uint8ListHolder;
