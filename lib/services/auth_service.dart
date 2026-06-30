import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService._();

  static const _prefKeys = [
    'token', 'refreshToken', 'userId', 'name', 'phone', 'familyId', 'familyName', 'role'
  ];

  static Future<AuthUser> login(LoginRequest req) async {
    final resp = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(req.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200) {
      throw AuthException(body['message'] as String? ?? '登录失败');
    }
    final user = AuthUser.fromJson(body['data'] as Map<String, dynamic>);
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
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw AuthException(body['message'] as String? ?? '注册失败');
    }
    final user = AuthUser.fromJson(body['data'] as Map<String, dynamic>);
    await persistUser(user);
    return user;
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
