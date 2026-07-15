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

  /// `POST /moment` — §7.1. Client must have already uploaded each
  /// piece of media via `/users/upload/{image,video,audio}` (§2.4 /
  /// §2.5 / §2.6) and pass the resulting URLs here; this service
  /// does no upload work. The server rejects an empty payload with
  /// 400 `MOMENT_CONTENT_EMPTY` — so we map both `content` and
  /// `media` to `null`/empty in the JSON when they're absent, rather
  /// than dropping the key entirely.
  Future<void> publishMoment({
    String? content,
    required List<Map<String, String>> media,
  }) async {
    if ((content == null || content.trim().isEmpty) && media.isEmpty) {
      throw StateError(
          'publishMoment requires either content or media (server enforces same via §7.8 MOMENT_CONTENT_EMPTY)');
    }
    final body = <String, dynamic>{
      'content': content ?? '',
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
}
