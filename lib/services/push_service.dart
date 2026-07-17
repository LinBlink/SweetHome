import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import 'api_client.dart';
import '../models/auth_models.dart';

/// JPush integration for §2.7 push-token registration. Owns the
/// plugin's lifecycle (setup, event listeners, registration-ID fetch)
/// and exposes a tiny REST surface for the auth provider to register
/// or deregister the device's `registrationId` on login/logout.
///
/// **Platform config:**
///   - Android: `android/app/build.gradle.kts` sets the
///     `JPUSH_APPKEY` manifest placeholder to the same JIGUANG
///     console app as the backend's `JPUSH_APP_KEY` (docs/API.md
///     §2.7).
///   - iOS Xcode project still needs the Push Notification
///     capability enabled and an APNs cert/key uploaded — cannot be
///     done from Dart/Gradle. Web is unsupported by JPush, so all
///     methods on this service degrade to no-ops on non-mobile
///     platforms (see [PushService.setup]).
///
/// **Wire-up:** [PushService] is constructed once at app startup and
/// `setup()` is called before the first frame. [registerForUser] is
/// invoked by `AuthProvider.login`/`register` after a successful auth
/// round-trip; [deregisterForUser] by `AuthProvider.logout` *before*
/// the local credentials are wiped (the JWT is still in the
/// Authorization header at that point).
class PushService {
  PushService();

  final JPushFlutterInterface _jpush = JPush.newJPush();

  /// True after [setup] has run successfully on the underlying plugin.
  bool _initialized = false;

  /// Cached registration ID — null until the SDK reports one (usually
  /// within seconds of [setup]). Persisted to `SharedPreferences` so
  /// the token survives app restarts and can be deregistered on the
  /// next `logout()` even if the SDK hasn't finished init yet.
  String? _registrationId;
  String? get registrationId => _registrationId;

  /// One-shot completion the UI can await to know when the device is
  /// ready to receive pushes. Completes immediately when JPush isn't
  /// supported (web/desktop) or `setup` fails so callers never block.
  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  /// Tap-handling stream. Emits the `extras` map of a tapped
  /// notification — server-side fence-alarm pushes carry
  /// `{"type": "fence_alarm", "alarmId": "..."}` which the navigator
  /// listener uses to deep-link into `FenceAlarmScreen`.
  final _onTapController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTap => _onTapController.stream;

  static const _prefKeyRegistrationId = 'jpush_registration_id';

  /// Initializes the JPush SDK. Idempotent — calling more than once is a
  /// no-op. Returns immediately on platforms where JPush isn't supported
  /// (web, desktop) without throwing.
  Future<void> setup({required bool production}) async {
    if (_initialized) return;
    if (!_isSupportedPlatform) {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    try {
      // `appKey` is read from the native manifest placeholders
      // (Android) / Info.plist (iOS) at the plugin level — passing
      // an empty string here keeps the SDK reading its baked-in key.
      _jpush.setup(
        appKey: '',
        production: production,
        channel: 'developer-default',
        debug: !production,
      );
      _jpush.addEventHandler(
        onReceiveNotification: (event) async {
          debugPrint('JPush onReceiveNotification: $event');
        },
        onOpenNotification: (event) async {
          final extras = _extractExtras(event);
          if (extras != null) _onTapController.add(extras);
        },
        onReceiveMessage: (event) async {
          final extras = _extractExtras(event);
          if (extras != null) _onTapController.add(extras);
        },
        onConnected: (_) async {
          await _refreshRegistrationId();
        },
      );
      // Request runtime permission on Android 13+ / iOS — without this,
      // notifications fire silently (no system tray banner). The
      // plugin's `applyPushAuthority` accepts a single
      // `NotificationSettingsIOS` shape and applies it to both
      // platforms (Android reuses the same type for sound/alert/badge).
      try {
        _jpush.applyPushAuthority(
          const NotificationSettingsIOS(
            sound: true,
            alert: true,
            badge: true,
          ),
        );
      } catch (e) {
        debugPrint('JPush applyPushAuthority failed: $e');
      }
      await _refreshRegistrationId();
      _initialized = true;
      if (!_ready.isCompleted) _ready.complete();
    } catch (e) {
      debugPrint('JPush setup failed: $e');
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Pulls the registration ID from the SDK and caches it (both
  /// in-memory and in `SharedPreferences`). Returns null if JPush
  /// isn't ready yet — the next `onConnected` event will trigger a
  /// re-fetch. Per JPush docs the ID can be the string `"null"` on
  /// Android when manifest placeholders are missing; we filter that
  /// out so the server never sees it.
  Future<String?> _refreshRegistrationId() async {
    if (!_isSupportedPlatform) return null;
    try {
      final id = await _jpush.getRegistrationID();
      if (id.isEmpty || id == 'null') return null;
      _registrationId = id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyRegistrationId, id);
      return id;
    } catch (e) {
      debugPrint('JPush getRegistrationID failed: $e');
      return null;
    }
  }

  /// Loads a previously-persisted registration ID (if any) into
  /// memory. Called at app startup so a `logout()` after a process
  /// kill can still deregister even if JPush hasn't finished
  /// reconnecting yet.
  Future<void> restoreCachedRegistrationId() async {
    if (!_isSupportedPlatform) return;
    final prefs = await SharedPreferences.getInstance();
    _registrationId = prefs.getString(_prefKeyRegistrationId);
  }

  /// `POST /users/push-token` (§2.7.1). Best-effort — the auth flow
  /// doesn't block on push registration, and a failure here is logged
  /// but doesn't surface to the UI (the user is already logged in
  /// and using the app). Uses the user's current JWT as the bearer
  /// token — the call must happen *after* the JWT is in hand, not
  /// before.
  Future<void> registerForUser(AuthUser user) async {
    if (!_isSupportedPlatform) return;
    if (AppConfig.mockMode) return;
    final id = _registrationId;
    if (id == null) {
      debugPrint('JPush registerForUser: no registrationId available');
      return;
    }
    try {
      final resp = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/users/push-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${user.token}',
            },
            body: jsonEncode({
              'registrationId': id,
              'platform': _platformName,
            }),
          )
          .timeout(const Duration(seconds: 10));
      ApiClient.unwrap(resp);
    } catch (e) {
      debugPrint('JPush registerForUser failed: $e');
    }
  }

  /// `DELETE /users/push-token` (§2.7.2). Called *before* the local
  /// credentials are wiped so the JWT is still valid for this single
  /// request. Tolerant of network failures (logout must continue even
  /// if the server can't be reached).
  Future<void> deregisterForUser(AuthUser user) async {
    if (!_isSupportedPlatform) return;
    if (AppConfig.mockMode) return;
    final id = _registrationId;
    if (id == null) return;
    try {
      final resp = await http
          .delete(
            Uri.parse('${AppConfig.apiBaseUrl}/users/push-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${user.token}',
            },
            body: jsonEncode({'registrationId': id}),
          )
          .timeout(const Duration(seconds: 10));
      ApiClient.unwrap(resp);
    } catch (e) {
      debugPrint('JPush deregisterForUser failed: $e');
    }
    _registrationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyRegistrationId);
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'unknown';
  }

  Map<String, dynamic>? _extractExtras(dynamic event) {
    if (event is! Map) return null;
    final raw = event['extras'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}