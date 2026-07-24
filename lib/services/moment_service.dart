import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/moment.dart';
import 'api_client.dart';

/// REST client for the §7 family-feed sub-service (`moment-service`,
/// port 8086). Streaming-publish via WebSocket is not defined in the
/// spec — moments always go through REST (§7.1), so this service is
/// HTTP-only.
///
/// Like-counters use an `INSERT ... ON DUPLICATE KEY UPDATE` on the
/// server (see §7.4 business logic), so the client never has to
/// coordinate "is this a like or an unlike" beforehand — calling
/// `like()` repeatedly just increments the per-user count, and
/// `unlike()` deletes the entire row per §7.5 ("取消点赞是把这个
/// 用户在这条动态下的点赞记录整行删除（清零），不是把 like_count
/// 减一"). We surface that semantic distinction in the provider
/// layer.
class MomentService {
  final String Function() _tokenProvider;
  MomentService(this._tokenProvider);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_tokenProvider()}',
      };

  /// `GET /moment/myfamily?page=&pageSize=&asc=` — §7.2. The server
  /// returns newest-first by default (`asc=false`); pass `true` if
  /// the caller prefers chronological.
  Future<MomentPage> fetchFamilyMoments({
    int page = 1,
    int pageSize = 10,
    bool asc = false,
  }) async {
    final resp = await http
        .get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/moment/myfamily?page=$page&pageSize=$pageSize&asc=$asc'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    final list = (data['moments'] as List<dynamic>? ?? const [])
        .map((e) => Moment.fromJson(e as Map<String, dynamic>))
        .toList();
    return MomentPage(
      moments: list,
      total: data['total'] as int? ?? list.length,
    );
  }

  /// `GET /moment/public?page=&pageSize=&asc=` — §7.3. The cross-family
  /// "广场" feed: only moments where `is_public = true` show up,
  /// regardless of which family the viewer belongs to. The same
  /// page-wrapper shape as [fetchFamilyMoments]; the rows carry the
  /// extra `familyId`/`familyName` fields the §7.3 spec adds for
  /// disambiguation. `Moment.fromJson` already handles either shape
  /// (the two family-fields just stay `null` on §7.2 rows), so callers
  /// don't need a separate DTO.
  Future<MomentPage> fetchPublicMoments({
    int page = 1,
    int pageSize = 10,
    bool asc = false,
  }) async {
    final resp = await http
        .get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/moment/public?page=$page&pageSize=$pageSize&asc=$asc'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    final list = (data['moments'] as List<dynamic>? ?? const [])
        .map((e) => Moment.fromJson(e as Map<String, dynamic>))
        .toList();
    return MomentPage(
      moments: list,
      total: data['total'] as int? ?? list.length,
    );
  }

  /// `POST /moment` — §7.1. Client must have already uploaded each
  /// piece of media via `/users/upload/{image,video,audio}` (§2.4 /
  /// §2.5 / §2.6) and pass the resulting URLs here; this service
  /// does no upload work. The server rejects an empty payload with
  /// 400 `MOMENT_CONTENT_EMPTY` — so we map both `content` and
  /// `media` to `null`/empty in the JSON when they're absent, rather
  /// than dropping the key entirely.
  ///
  /// Pass `isPublic: true` to send the moment across families (the
  /// §7.3 cross-family 广场). The server defaults to family-only when
  /// the field is omitted, and that's also our default — flipping the
  /// composer's "公开发布" switch is the only way to set this on.
  Future<void> publishMoment({
    String? content,
    required List<Map<String, String>> media,
    bool isPublic = false,
  }) async {
    if ((content == null || content.trim().isEmpty) && media.isEmpty) {
      throw StateError(
          'publishMoment requires either content or media (server enforces same via §7.8 MOMENT_CONTENT_EMPTY)');
    }
    final body = <String, dynamic>{
      'content': content ?? '',
      // Always include the key — server defaults to `false` if absent
      // (per §7.1 schema), but being explicit avoids the round-trip
      // ambiguity on Flutter web where the JSON serializer could
      // collapse absent null-equivalent booleans.
      'isPublic': isPublic,
    };
    body['media'] = media
        .map((m) => {'type': m['type'], 'content': m['content']})
        .toList();
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/moment'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    ApiClient.unwrap(resp);
  }

  /// `DELETE /moment/{momentId}` — §7.3. Only the original publisher
  /// may delete — server returns 403 `NOT_MOMENT_OWNER` otherwise.
  Future<void> deleteMoment(int momentId) async {
    final resp = await http
        .delete(
          Uri.parse('${AppConfig.apiBaseUrl}/moment/$momentId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// `POST /moment/liker/{momentId}` — §7.4. Idempotent at the
  /// display level: each call increments the per-user count by 1,
  /// and the server returns 200 either way (no error for "already
  /// liked"). Returns no payload.
  Future<void> likeMoment(int momentId) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/moment/liker/$momentId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// `DELETE /moment/liker/{momentId}` — §7.5. Clears the entire
  /// per-user row (sets `like_count` back to 0 effectively, not -1).
  /// 404 `NO_SUCH_LIKE_RECORD` if the user never liked the moment.
  Future<void> unlikeMoment(int momentId) async {
    final resp = await http
        .delete(
          Uri.parse('${AppConfig.apiBaseUrl}/moment/liker/$momentId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// `GET /moment/liker/{momentId}/like-count` — §7.6. `SUM(like_count)`
  /// over the moment; `COALESCE(SUM(like_count), 0)` server-side
  /// guarantees a non-null 0 when nobody has liked yet.
  Future<int> fetchLikeCount(int momentId) async {
    final resp = await http
        .get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/moment/liker/$momentId/like-count'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp);
    if (data is int) return data;
    return (data as num).toInt();
  }

  /// `GET /moment/liker/{momentId}/like-detail` — §7.7. Powers the
  /// "who liked this" bottom sheet on the moment detail screen.
  Future<MomentLikeDetail> fetchLikeDetail(int momentId) async {
    final resp = await http
        .get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/moment/liker/$momentId/like-detail'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return MomentLikeDetail.fromJson(data);
  }

  /// `GET /moment/comment/{momentId}` — §7.9. Returns the moment's
  /// full comment list ordered oldest-first (the server-side default,
  /// deliberately opposite to the feed's newest-first so comment
  /// threads read top-down chronologically).
  Future<List<MomentComment>> fetchComments(int momentId) async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/moment/comment/$momentId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data
        .map((e) => MomentComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /moment/comment/{momentId}` — §7.8. Server validates that
  /// the body has a non-blank `content` (400 `COMMENT_CONTENT_EMPTY`
  /// otherwise) and returns `data: null` on success. Caller is
  /// expected to refresh the list (the server doesn't echo the new
  /// row back).
  Future<void> addComment(int momentId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw StateError(
          'addComment requires non-blank content (server enforces §7.8 COMMENT_CONTENT_EMPTY)');
    }
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/moment/comment/$momentId'),
          headers: _headers,
          body: jsonEncode({'content': trimmed}),
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// `DELETE /moment/comment/{commentId}` — §7.10. Only the comment
  /// author may delete — server returns 403 `NOT_COMMENT_OWNER`
  /// otherwise. Server performs a soft-delete (sets `deleted_at`),
  /// but the next `GET /moment/comment/{momentId}` filters it out so
  /// a list refresh is sufficient to update the UI.
  Future<void> deleteComment(int commentId) async {
    final resp = await http
        .delete(
          Uri.parse('${AppConfig.apiBaseUrl}/moment/comment/$commentId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }
}
