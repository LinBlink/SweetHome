import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/family_member_vm.dart';
import '../models/join_request.dart';
import 'api_client.dart';

class FamilyService {
  final String Function() _tokenProvider;
  FamilyService(this._tokenProvider);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_tokenProvider()}',
      };

  Future<List<FamilyMemberVm>> fetchMembers(int familyId) async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/families/$familyId/members'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final list = ApiClient.unwrap(resp) as List<dynamic>;
    return list.map((e) => FamilyMemberVm.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `GET /families/{familyId}/join-requests?status=pending` —
  /// docs/api.md §3.5.2. Returns the list of pending join requests
  /// for admin review. The query string filter is enforced server-side;
  /// we still pass `?status=pending` for clarity in case the API
  /// later introduces a `status=all` variant.
  Future<List<JoinRequest>> fetchJoinRequests(int familyId) async {
    final resp = await http
        .get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/families/$familyId/join-requests?status=pending'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final list = ApiClient.unwrap(resp) as List<dynamic>;
    return list
        .map((e) => JoinRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /families/join-requests/{requestId}/approve` —
  /// docs/api.md §3.5.3. Backend creates the `users` row + family
  /// membership on success. Returns the updated request's status.
  Future<String> approveJoinRequest(int familyId, int requestId) async {
    final resp = await http
        .post(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/families/join-requests/$requestId/approve'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return data['status'] as String;
  }

  /// `POST /families/join-requests/{requestId}/reject` —
  /// docs/api.md §3.5.3. [reason] is optional; backend stores it
  /// alongside `resolved_at` / `resolved_by` but doesn't surface it
  /// back to the requester.
  Future<String> rejectJoinRequest(
    int familyId,
    int requestId, {
    String? reason,
  }) async {
    final body = reason == null || reason.isEmpty
        ? <String, dynamic>{}
        : <String, dynamic>{'reason': reason};
    final resp = await http
        .post(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/families/join-requests/$requestId/reject'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return data['status'] as String;
  }

  /// `POST /families/join-requests` — docs/api.md §3.5.1. Public
  /// endpoint (no auth required, the requester doesn't have an
  /// account yet). Returns the created request's id + status.
  /// Implemented as a static method because it doesn't need the
  /// current user's token.
  static Future<({int requestId, String status})> submitJoinRequest({
    required String name,
    required String phone,
    required String password,
    required String gender,
    required String targetMemberPhone,
    required String relationType,
    String? message,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'gender': gender,
      'targetMemberPhone': targetMemberPhone,
      'relationType': relationType,
    };
    if (message != null && message.isNotEmpty) body['message'] = message;
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/families/join-requests'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return (
      requestId: data['requestId'] as int,
      status: data['status'] as String,
    );
  }

  Future<InviteCodeInfo> generateInviteCode(int familyId) async {
    final resp = await http
        .post(Uri.parse('${AppConfig.apiBaseUrl}/families/$familyId/invite'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return InviteCodeInfo.fromJson(data);
  }

  /// `POST /families/join` — see docs/api.md §3.4. Returns the joined
  /// family's `(familyId, familyName)`, same shape as §3.1; the server also
  /// cascades a "leave the previous family" side effect (see §3.4 business
  /// logic), which the client doesn't need to do anything for.
  Future<({int familyId, String familyName})> joinFamily({
    required String inviteCode,
    required String gender,
    required int relationToMemberId,
    required String relationType,
  }) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/families/join'),
          headers: _headers,
          body: jsonEncode({
            'inviteCode': inviteCode,
            'gender': gender,
            'relationToMemberId': relationToMemberId,
            'relationType': relationType,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return (familyId: data['familyId'] as int, familyName: data['name'] as String);
  }

  static Future<FamilyPreview> lookupByInviteCode(String inviteCode) async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/families/lookup?inviteCode=$inviteCode'))
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return FamilyPreview.fromJson(data);
  }
}
