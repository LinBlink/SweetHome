import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/fence.dart';
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

  /// `GET /location/{targetUserId}/history?date=YYYY-MM-DD` —
  /// docs/api.md §6.3. The server returns the day's raw history log
  /// sorted ASC by `updatedAt`. The client draws the polyline in
  /// that order; no client-side sort.
  Future<LocationHistory> fetchLocationHistory({
    required int targetUserId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/location/$targetUserId/history?date=$dateStr',
    );
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return LocationHistory.fromJson(data);
  }

  /// `GET /location/fence` — docs/api.md §6.6. Returns ALL fences in
  /// the current user's family (not just the ones they set).
  Future<List<Fence>> listFences() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/location/fence'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data.map((e) => Fence.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `POST /location/fence` — docs/api.md §6.4. [rangeMeters] must
  /// be > 0; the server returns 400 LOCATION_FENCE_RANGE_INVALID
  /// otherwise. The caller (the geofence creation screen) is
  /// expected to validate locally too so it doesn't even hit the
  /// server with a bad value.
  Future<void> createFence({
    required int targetUserId,
    required double fenceLng,
    required double fenceLat,
    required double rangeMeters,
    String? name,
  }) async {
    final body = <String, dynamic>{
      'targetUserId': targetUserId,
      'fenceLng': fenceLng,
      'fenceLat': fenceLat,
      'fenceRange': rangeMeters,
    };
    if (name != null && name.isNotEmpty) body['name'] = name;
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/location/fence'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// `DELETE /location/fence/{fenceId}` — docs/api.md §6.5. Only the
  /// original setter can delete; server returns 403 NOT_FENCE_SETTER
  /// otherwise. Soft-delete on the server side; the historical
  /// alarms (6.7) for that fence are preserved.
  Future<void> deleteFence(int fenceId) async {
    final resp = await http
        .delete(
          Uri.parse('${AppConfig.apiBaseUrl}/location/fence/$fenceId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// `GET /location/fence-alarm` — docs/api.md §6.7. Returns the
  /// alarm history of fences the current user set (the notification
  /// target, not the watched person). Sorted DESC by `alarmedAt` per
  /// the server contract.
  Future<List<FenceAlarm>> listFenceAlarms() async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/location/fence-alarm'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data
        .map((e) => FenceAlarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
