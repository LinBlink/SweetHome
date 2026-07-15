import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/error_messages.dart';
import '../models/api_exception.dart';

/// Unwraps the backend's unified `{code, message, data}` response envelope.
/// Throws [ApiException] whenever `code != 200`, regardless of HTTP status.
class ApiClient {
  ApiClient._();

  /// Fired on every `code == 401` response, from *any* service that
  /// routes through [unwrap] — `ChatService`, `FamilyService`,
  /// `LocationService`, `AuthService`'s own non-refresh calls, all of
  /// it. `AuthProvider` self-registers a handler here in its
  /// constructor (session-invalid → try a silent refresh, else log
  /// out) so a 401 anywhere in the app bounces the user back to
  /// `LoginScreen` via `AuthGate`'s reactive rebuild, instead of only
  /// working for the one call site (`ChatProvider`) that happened to
  /// have its own bespoke 401 handling.
  static void Function()? onUnauthorized;

  static dynamic unwrap(http.Response resp) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final code = body['code'] as int? ?? resp.statusCode;
    if (code == 401) {
      onUnauthorized?.call();
    }
    if (code != 200) {
      // Service layer emits only the SENTINEL, not a hardcoded
      // Chinese message. The UI layer routes the sentinel through
      // `localizeErrorMessage` to render the active locale's text.
      throw ApiException(
        code,
        body['message'] as String? ?? kNetworkErrorSentinel,
      );
    }
    return body['data'];
  }
}
