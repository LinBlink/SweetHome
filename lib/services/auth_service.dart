import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthService {
  // Override at build/run time via: flutter run --dart-define=API_BASE_URL=http://10.0.2.2/api/v1
  //   Android emulator, direct backend : http://10.0.2.2:8080/api/v1  (default)
  //   Android emulator, through Nginx  : http://10.0.2.2/api/v1
  //   Physical device / web            : http://<host-ip>/api/v1
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const String _keyToken = 'auth_token';
  static const String _keyName = 'user_name';
  static const String _keyFamilyName = 'family_name';
  static const String _keyPhone = 'user_phone';

  static Future<AuthUser> login(LoginRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(req.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final user = AuthUser.fromJson(json['data'] as Map<String, dynamic>);
        await _persistUser(user);
        return user;
      } else if (response.statusCode == 401) {
        throw AuthException(_tryDecodeError(response.body) ?? '手机号或密码错误');
      } else {
        throw AuthException(_tryDecodeError(response.body) ?? '登录失败，请稍后重试');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException('连接服务器失败，请检查网络或服务是否启动');
    }
  }

  static Future<AuthUser> register(RegisterRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(req.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final user = AuthUser.fromJson(json['data'] as Map<String, dynamic>);
        await _persistUser(user);
        return user;
      } else if (response.statusCode == 409) {
        throw AuthException(_tryDecodeError(response.body) ?? '该手机号已注册，请直接登录');
      } else if (response.statusCode == 400) {
        throw AuthException(_tryDecodeError(response.body) ?? '注册信息有误，请检查后重试');
      } else {
        throw AuthException(_tryDecodeError(response.body) ?? '注册失败，请稍后重试');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw const AuthException('连接服务器失败，请检查网络或服务是否启动');
    }
  }

  static Future<void> _persistUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, user.token);
    await prefs.setString(_keyName, user.name);
    await prefs.setString(_keyFamilyName, user.familyName);
    await prefs.setString(_keyPhone, user.phone);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getFamilyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFamilyName);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyFamilyName);
    await prefs.remove(_keyPhone);
  }

  static String? _tryDecodeError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
