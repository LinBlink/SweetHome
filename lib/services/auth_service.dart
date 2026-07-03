import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import '../models/auth_models.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static const _prefKeys = [
    'token', 'refreshToken', 'userId', 'name', 'phone', 'familyId', 'familyName', 'role', 'gender'
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
