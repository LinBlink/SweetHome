import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/location.dart';
import 'api_client.dart';

/// REST client for the §6 location sub-service. `POST /location/report`
/// and `GET /location/family` both sit behind the same gateway, so
/// the same JWT/Authorization pattern as the other services applies.
class LocationService {
  final String Function() _tokenProvider;
  LocationService(this._tokenProvider);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_tokenProvider()}',
  };

  /// `GET /location/family` — docs/api.md §6.2. Returns the calling
  /// user's whole family's member positions; members with no live
  /// data in the last 10 min are simply absent from the
  /// `familyMemberLocations` list (the server doesn't fabricate
  /// placeholder rows for offline members).
  Future<FamilyLocations> fetchFamilyLocations() async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/location/family'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return FamilyLocations.fromJson(data);
  }

  /// `POST /location/report` — docs/api.md §6.1. Server rejects
  /// requests whose `updateTime` is more than 10 minutes in the
  /// past (LOCATION_TIMESTAMP_STALE) — the caller is expected to
  /// pass a fresh fix's local time, not e.g. a cached last-known
  /// value from app start.
  Future<void> reportPosition(LocationReport report) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/location/report'),
          headers: _headers,
          body: jsonEncode(report.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }
}
