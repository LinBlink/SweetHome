import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/health_record.dart';
import 'api_client.dart';

/// REST client for the §8 Health Service.
///
/// All 7 endpoints are behind `/api/v1/health/**` and require the
/// standard `Authorization: Bearer <jwt>` header.
class HealthService {
  final String Function() _tokenProvider;
  HealthService(this._tokenProvider);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_tokenProvider()}',
  };

  /// §8.1 — Submit a health record (upsert by same-day same-metric).
  Future<HealthRecord> submitRecord({
    required HealthMetricType metricType,
    required double value,
    double? valueSecondary,
    String? recordedAt,
  }) async {
    final body = <String, dynamic>{
      'metricType': healthMetricTypeToWire(metricType),
      'value': value,
    };
    if (valueSecondary != null) body['valueSecondary'] = valueSecondary;
    if (recordedAt != null) body['recordedAt'] = recordedAt;
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/health/records'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return HealthRecord.fromJson(data);
  }

  /// §8.3 — Manually update an existing record.
  ///
  /// [metricType] is intentionally NOT in the wire body — the spec
  /// locks it on the original record, so even a stale client that
  /// tries to retag a height sample as weight would be silently
  /// ignored (the server only reads `value` / `valueSecondary` /
  /// `recordedAt` from this endpoint). Pass `recordedAt == null` to
  /// keep the existing date.
  Future<HealthRecord> updateRecord({
    required int recordId,
    required double value,
    double? valueSecondary,
    String? recordedAt,
  }) async {
    final body = <String, dynamic>{'value': value};
    if (valueSecondary != null) body['valueSecondary'] = valueSecondary;
    if (recordedAt != null) body['recordedAt'] = recordedAt;
    final resp = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/health/records/$recordId'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return HealthRecord.fromJson(data);
  }

  /// §8.2 — Query own health record history, paginated.
  Future<List<HealthRecord>> queryOwnRecords({
    HealthMetricType? metricType,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 30,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (metricType != null) params['metricType'] = healthMetricTypeToWire(metricType);
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/health/records').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data.map((e) => HealthRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// §8.3 — Query a family member's public health records.
  ///
  /// Privacy semantics: if the target member hasn't made the
  /// requested metric type public, returns empty list (not error).
  Future<List<HealthRecord>> queryFamilyRecords({
    required int memberId,
    HealthMetricType? metricType,
    String? from,
    String? to,
    int page = 1,
    int pageSize = 30,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (metricType != null) params['metricType'] = healthMetricTypeToWire(metricType);
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/health/records/family/$memberId',
    ).replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data.map((e) => HealthRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// §8.4 — Query own visibility settings.
  Future<List<HealthVisibility>> queryVisibility() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/health/visibility'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as List<dynamic>;
    return data
        .map((e) => HealthVisibility.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// §8.5 — Modify one metric's visibility.
  Future<void> updateVisibility({
    required HealthMetricType metricType,
    required bool visible,
  }) async {
    final resp = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/health/visibility'),
          headers: _headers,
          body: jsonEncode({
            'metricType': healthMetricTypeToWire(metricType),
            'visible': visible,
          }),
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }

  /// §8.6 — Query own reminder settings.
  Future<HealthReminder> queryReminder() async {
    final resp = await http
        .get(Uri.parse('${AppConfig.apiBaseUrl}/health/reminder'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return HealthReminder.fromJson(data);
  }

  /// §8.7 — Modify own reminder settings.
  Future<void> updateReminder({
    required String remindTime,
    required bool enabled,
  }) async {
    final resp = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/health/reminder'),
          headers: _headers,
          body: jsonEncode({
            'remindTime': remindTime,
            'enabled': enabled,
          }),
        )
        .timeout(const Duration(seconds: 10));
    ApiClient.unwrap(resp);
  }
}
