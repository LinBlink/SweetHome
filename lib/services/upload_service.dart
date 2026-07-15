import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../core/app_config.dart';
import '../models/auth_models.dart';
import 'api_client.dart';

/// Generic attachment upload pipeline (docs/api.md §2.3–§2.6).
/// Concentrates the multipart boilerplate in one place — the four
/// endpoints all share the same shape (multipart/form-data with a
/// single field named `file`; backend enforces `*/{avatars,photos,
/// videos,audios}` plus a per-route size cap and a MIME-prefix check
/// like `image/*` / `video/*` / `audio/*`).
///
/// The MIME sniffing rules per docs:
/// - §2.3 avatar:  image/*, <=500KB
/// - §2.4 photo:   image/*, <=1MB
/// - §2.5 video:   video/*, <=50MB, **must be mp4**
/// - §2.6 audio:   audio/*, <=10MB, **must be opus**
///
/// The `mp4` and `opus` format requirements are not validated by
/// the server (no transcode pass) — the client must produce them
/// before uploading. Methods that take a [contentType] argument
/// trust whatever the caller computes; methods that take raw bytes
/// fall back to a magic-byte sniff where one exists.
class UploadService {
  UploadService();

  /// `POST /users/upload/avatar`. Caller passes the user's session so
  /// the bearer token travels with the upload. The backend writes the
  /// file to R2 AND flips `users.avatar_url` to the new URL
  /// atomically — return value is the new public URL.
  Future<String> uploadAvatar(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _upload(
      url: '${AppConfig.apiBaseUrl}/users/upload/avatar',
      token: current.token,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      sizeLimit: 500 * 1024,
      kind: 'avatar',
    );
  }

  /// `POST /users/upload/image` (chat image). Does NOT touch
  /// `users.avatar_url` — returning a bare R2 URL for the caller to
  /// embed as `Message.content` via §4.4/§5.2.
  Future<String> uploadImage(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _upload(
      url: '${AppConfig.apiBaseUrl}/users/upload/image',
      token: current.token,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      sizeLimit: 1024 * 1024,
      kind: 'image',
    );
  }

  /// `POST /users/upload/video` (Moment media). Hard requirement: the
  /// bytes must already be mp4 — server stores them verbatim.
  Future<String> uploadVideo(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _upload(
      url: '${AppConfig.apiBaseUrl}/users/upload/video',
      token: current.token,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      sizeLimit: 50 * 1024 * 1024,
      kind: 'video',
    );
  }

  /// `POST /users/upload/audio` (Moment media + future chat voice
  /// messages). Hard requirement: the bytes must already be opus.
  Future<String> uploadAudio(
    AuthUser current, {
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) {
    return _upload(
      url: '${AppConfig.apiBaseUrl}/users/upload/audio',
      token: current.token,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      sizeLimit: 10 * 1024 * 1024,
      kind: 'audio',
    );
  }

  Future<String> _upload({
    required String url,
    required String token,
    required Uint8List bytes,
    required String filename,
    String? contentType,
    required int sizeLimit,
    required String kind,
  }) async {
    if (bytes.isEmpty) {
      throw _clientError('EMPTY_FILE: empty $kind upload', 400);
    }
    if (bytes.length > sizeLimit) {
      throw _clientError(
        'FILE_SIZE_ILLEGAL: $kind exceeds server cap '
        '${(sizeLimit / 1024).round()}KB '
        '(got ${(bytes.length / 1024).round()}KB)',
        400,
      );
    }
    final req = http.MultipartRequest('POST', Uri.parse(url));
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: _parseMediaType(contentType),
    ));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final resp = await http.Response.fromStream(streamed);
    final data = ApiClient.unwrap(resp) as Map<String, dynamic>;
    return data['addressReturn'] as String;
  }

  // Tiny helper so we don't have to import `ApiException` here —
  // callers wrap these into ApiException when surfacing to UI.
  Exception _clientError(String message, int code) =>
      Exception('$code $message');

  /// Parses a `type/subtype` string into the `MediaType` the `http`
  /// package wants. Returns `null` on missing / malformed input —
  /// `MultipartFile` then falls back to its filename-extension guess.
  static MediaType? _parseMediaType(String? mime) {
    if (mime == null) return null;
    final slash = mime.indexOf('/');
    if (slash <= 0 || slash == mime.length - 1) return null;
    return MediaType(mime.substring(0, slash), mime.substring(slash + 1));
  }
}
