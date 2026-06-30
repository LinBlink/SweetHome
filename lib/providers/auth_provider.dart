import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../data/mock_data.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = true;
  String? _error;

  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (AppConfig.mockMode) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      _currentUser = await AuthService.loadUser();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String phone, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      if (AppConfig.mockMode) {
        await Future.delayed(const Duration(milliseconds: 600));
        _currentUser = MockDataSource.mockUser;
      } else {
        _currentUser =
            await AuthService.login(LoginRequest(phone: phone, password: password));
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '网络连接失败，请稍后重试';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String name,
    String phone,
    String password, {
    String? familyName,
    String? inviteCode,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      if (AppConfig.mockMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        _currentUser = MockDataSource.mockUser;
      } else {
        _currentUser = await AuthService.register(
          RegisterRequest(
            name: name,
            phone: phone,
            password: password,
            familyName: familyName,
            inviteCode: inviteCode,
          ),
        );
      }
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '网络连接失败，请稍后重试';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final refresh = _currentUser?.refreshToken ?? '';
    _currentUser = null;
    notifyListeners();
    if (!AppConfig.mockMode) {
      await AuthService.logout(refresh);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
