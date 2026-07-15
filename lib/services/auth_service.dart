import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import '../models/auth_models.dart';
import 'api_client.dart';
import 'upload_service.dart';

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
  }) {
    return _uploader(current).uploadAvatar(
      current,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  /// `POST /users/upload/image` (docs/api.md §2.4) — multipart upload
  /// of a single chat image (field name `file`). Returns a public
  /// Cloudflare R2 URL that the caller should pass back as
  /// `Message.content` with `type = "image"` via §4.4 (REST) or §5.2
  /// (WS). Does **not** update `users.avatar_url` — uploading a chat
  /// image is not the same operation as replacing the avatar.
  static Future<String> uploadImage(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _uploader(current).uploadImage(
      current,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  /// `POST /users/upload/video` (docs/api.md §2.5) — used by the
  /// family-feed (§7) composer. Caller is responsible for the spec's
  /// "前端必须保证上传前已将视频极致压缩为 mp4 格式" requirement;
  /// the server does not transcode.
  static Future<String> uploadVideo(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _uploader(current).uploadVideo(
      current,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  /// `POST /users/upload/audio` (docs/api.md §2.6) — family-feed
  /// audio messages. Backend expects opus-encoded bytes per the
  /// spec; no server-side transcoding.
  static Future<String> uploadAudio(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _uploader(current).uploadAudio(
      current,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  static UploadService _uploader(AuthUser current) => UploadService();

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
