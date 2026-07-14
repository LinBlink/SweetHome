import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import '../models/auth_models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static const _prefKeys = [
    'token', 'refreshToken', 'userId', 'name', 'phone',
    'familyId', 'familyName', 'role', 'gender', 'avatarUrl',
  ];

  static Future<AuthUser> login(LoginRequest req) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    final user = AuthUser.fromJson(data);
    await persistUser(user);
    return user;
  }

  static Future<AuthUser> register(RegisterRequest req) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    final user = AuthUser.fromJson(data);
    await persistUser(user);
    return user;
  }

  /// `GET`/`PUT /users/me` return the flat user object with no token, so the
  /// caller's current session (token/refreshToken) is threaded through to
  /// rebuild a full [AuthUser] — see [AuthUser.fromUserFields].
  static Future<AuthUser> fetchMe(AuthUser current) async {
    final resp = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${current.token}'},
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return AuthUser.fromUserFields(data, token: current.token, refreshToken: current.refreshToken);
  }

  static Future<AuthUser> updateMe(AuthUser current, {required String name}) async {
    final resp = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}/users/me'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${current.token}'},
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return AuthUser.fromUserFields(data, token: current.token, refreshToken: current.refreshToken);
  }

  /// `POST /users/upload/avatar` (docs/api.md §2.3) — multipart upload of a
  /// single image file (field name `file`). The backend writes the file to
  /// Cloudflare R2 and returns the new public address; the server also
  /// updates `users.avatar_url` to that address, so we return the URL for
  /// the caller to drop straight into the local [AuthUser].
  ///
  /// [filename] is the part's filename (use the `XFile.name` from
  /// `image_picker`).
  ///
  /// [contentType] is the MIME type of the part — the backend's
  /// `UploadServiceImpl` calls `avatarFile.getContentType()` to enforce
  /// its `image/*` check, so the client must set the part's Content-Type
  /// explicitly. `image_picker` exposes this on `XFile.mimeType`; without
  /// it, the part would default to `application/octet-stream` and trip
  /// the `FILE_TYPE_ILLEGAL` 400.
  static Future<String> uploadAvatar(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/upload/avatar');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer ${current.token}';
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: _parseMediaType(contentType),
    ));
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return data['addressReturn'] as String;
  }

  /// `POST /users/upload/image` (docs/api.md §2.4) — multipart upload
  /// of a single chat image (field name `file`). Returns a public
  /// Cloudflare R2 URL that the caller should pass back as
  /// `Message.content` with `type = "image"` via §4.4 (REST) or §5.2
  /// (WS). Same validation rules as `/users/upload/avatar` except the
  /// size cap is 1 MB instead of 500 KB and the returned URL does NOT
  /// also update `users.avatar_url` — uploading a chat image does not
  /// accidentally change the user's avatar.
  ///
  /// [bytes] / [filename] / [contentType] follow the same shape as
  /// [uploadAvatar]; the backend's `image/*` check is satisfied the
  /// same way.
  static Future<String> uploadImage(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/upload/image');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer ${current.token}';
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: _parseMediaType(contentType),
    ));
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(streamed);
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return data['addressReturn'] as String;
  }

  /// Parses a `type/subtype` string into the `MediaType` the `http` package
  /// wants. Returns `null` on missing / malformed input — `MultipartFile`
  /// then falls back to its filename-extension guess (which already
  /// produces `image/jpeg` etc. for picker output, so missing mimeType
  /// isn't fatal — but the explicit form is the only way to guarantee
  /// the backend's `image/*` check sees a real image MIME).
  static MediaType? _parseMediaType(String? mime) {
    if (mime == null) return null;
    final slash = mime.indexOf('/');
    if (slash <= 0 || slash == mime.length - 1) return null;
    return MediaType(mime.substring(0, slash), mime.substring(slash + 1));
  }

  /// `POST /auth/refresh` — see docs/api.md §1.3. Exchanges a still-valid
  /// refresh token for a new short-lived JWT; the refresh token itself is
  /// not rotated.
  static Future<String> refresh(String refreshToken) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return data['token'] as String;
  }

  static Future<void> logout(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (_) {}
    await clearUser();
  }

  static Future<void> persistUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final map = user.toPrefs();
    for (final k in map.keys) {
      await prefs.setString(k, map[k]!);
    }
  }

  static Future<AuthUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final k in _prefKeys) k: prefs.getString(k)};
    return AuthUser.fromPrefs(map);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in _prefKeys) {
      await prefs.remove(k);
    }
  }
}
