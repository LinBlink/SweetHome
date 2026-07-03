import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_exception.dart';

/// Unwraps the backend's unified `{code, message, data}` response envelope.
/// Throws [ApiException] whenever `code != 200`, regardless of HTTP status.
class ApiClient {
  ApiClient._();

  static dynamic unwrap(http.Response resp) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? resp.statusCode;
    if (code != 200) {
      throw ApiException(code, body['message'] as String? ?? '请求失败，请稍后重试');
    }
    return body['data'];
  }
}
