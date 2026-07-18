import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/family_member_vm.dart';
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
