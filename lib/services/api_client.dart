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
    // Not every response that reaches us is the envelope. A gateway 502/504
    // serves an HTML error page, an idle-timeout kill serves an empty body,
    // and a misrouted request can serve anything at all. Decoding those blind
    // throws `FormatException`/`TypeError` — neither of which is an
    // `ApiException`, so every `catch (ApiException)` in the app misses it and
    // the failure surfaces as a raw crash instead of the localized network
    // error. Treat "not the envelope" as exactly that: a network-level error.
    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      body = decoded;
    } on FormatException {
      if (resp.statusCode == 401) onUnauthorized?.call();
      throw ApiException(resp.statusCode, kNetworkErrorSentinel);
    }

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
