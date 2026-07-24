import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/redpacket.dart';
import 'api_client.dart';

/// REST client for the §9 Red Packet Service. All four endpoints
/// (`/redpacket` and `/redpacket-grabs`) are behind the standard
/// `Authorization: Bearer <jwt>` header.
///
/// Service is stateless — same constructor pattern as `ChatService` /
/// `HealthService` (`(String Function()) tokenProvider`) so callers
/// can re-build it whenever the JWT rotates without leaking state.
class RedpacketService {
  final String Function() _tokenProvider;
  RedpacketService(this._tokenProvider);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_tokenProvider()}',
      };

  /// §9.1 — Create a red packet.
  ///
  /// [totalAmount] and [totalCount] are in the **wire** units — i.e.
  /// already in 分 (cents). Callers (the send screen) handle the
  /// 元→分 conversion up front. [conversationId] must be a
  /// conversation the sender is a member of; the server enforces
  /// `totalCount ≤ memberCount` and `totalAmount ≥ totalCount`.
  ///
  /// On success, returns the freshly-created [Redpacket] with
  /// `status = ongoing`. On `400 INSUFFICIENT_FUND`, `400
  /// INVALID_REDPACKET_AMOUNT`, `400
  /// REDPACKET_NUMBER_MORE_THAN_CONVERSATION_MEMBERS`, or `403
  /// NOT_CONVERSATION_MEMBER` the corresponding `ApiException` is
  /// thrown — the caller is expected to route through
  /// `localizeErrorMessage` for user-facing display.
  Future<Redpacket> create({
    required int totalAmount,
    required int totalCount,
    required int conversationId,
  }) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/redpacket'),
          headers: _headers,
          body: jsonEncode({
            'totalAmount': totalAmount,
            'totalCount': totalCount,
            'conversationId': conversationId,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return Redpacket.fromJson(data);
  }

  /// §9.2 — Fetch a single red packet by id. The caller must be a
  /// member of the conversation the red packet was sent into, or the
  /// server returns `403 NOT_CONVERSATION_MEMBER`. `404
  /// INVALID_REDPACKET` if the id doesn't exist.
  Future<Redpacket> getById(int id) async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/redpacket/$id'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return Redpacket.fromJson(data);
  }

  /// §9.3 — Claim a share of a red packet.
  ///
  /// The server is the source of truth for the claimed amount — per
  /// the §9 preamble's "抢红包在高并发异步落库设计" note, the
  /// response's `grabAmount` may show up milliseconds before the
  /// matching §9.4 grab-list row does. The caller should display
  /// `grabAmount` *immediately* rather than waiting for the list.
  /// `RedpacketGrab.id` is always `null` in this response (the DB row
  /// is written asynchronously) — see that field's doc comment.
  ///
  /// Possible failures: `400 PARAM_ERROR` (missing `redpacketId`),
  /// `404 INVALID_REDPACKET`, `400 REDPACKET_EXPIRED`, `403
  /// NOT_CONVERSATION_MEMBER`, `400 REDPACKET_GRABBED_ALREADY`, `400
  /// REDPACKET_EMPTY`.
  Future<RedpacketGrab> grab(int redpacketId) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/redpacket-grabs'),
          headers: _headers,
          body: jsonEncode({'redpacketId': redpacketId}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return RedpacketGrab.fromJson(data);
  }

  /// §9.4 — List every grab recorded against a red packet. Used by
  /// the detail screen's "Who has grabbed" pane. Same membership
  /// check as §9.2 applies. Each element has [RedpacketGrab.username]/
  /// [RedpacketGrab.userAvatarUrl] filled in (the grabber's info).
  Future<List<RedpacketGrab>> listGrabs(int redpacketId) async {
    final resp = await http
        .get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/redpacket-grabs?redpacketId=$redpacketId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data
        .map((e) => RedpacketGrab.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// §9.5 — Every red packet the current user has ever sent (used by
  /// the "我发出的" tab of [RedpacketRecordsScreen]). Identity comes
  /// from the JWT — no parameters. Not paginated/sorted server-side
  /// yet (per the §9.5 spec note); the caller sorts client-side if it
  /// wants newest-first.
  Future<List<Redpacket>> listSent() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/redpacket/i-sent'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data
        .map((e) => Redpacket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// §9.6 — Every red packet grab the current user has ever received
  /// (used by the "我收到的" tab of [RedpacketRecordsScreen]). Each
  /// element has [RedpacketGrab.redpacketOwnerId]/
  /// [RedpacketGrab.redpacketOwnerUsername]/
  /// [RedpacketGrab.redpacketOwnerUserAvatarUrl] filled in (who sent
  /// the red packet), not [RedpacketGrab.username] (the grabber is
  /// always the caller). Not paginated/sorted server-side yet, same
  /// as §9.5.
  Future<List<RedpacketGrab>> listReceived() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/redpacket-grabs/i-received'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data
        .map((e) => RedpacketGrab.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}