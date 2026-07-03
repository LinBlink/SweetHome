import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../core/error_messages.dart';
import '../data/mock_data.dart';
import '../models/api_exception.dart';
import '../models/auth_models.dart';
import '../models/family_member_vm.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

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
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = kNetworkErrorSentinel;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
    String name,
    String phone,
    String password, {
    required String gender,
    String? familyName,
    String? inviteCode,
    int? relationToMemberId,
    String? relationType,
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
            gender: gender,
            familyName: familyName,
            inviteCode: inviteCode,
            relationToMemberId: relationToMemberId,
            relationType: relationType,
          ),
        );
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = kNetworkErrorSentinel;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FamilyPreview> lookupFamily(String inviteCode) {
    if (AppConfig.mockMode) {
      return Future.value(MockDataSource.lookupByInviteCode(inviteCode));
    }
    return FamilyService.lookupByInviteCode(inviteCode);
  }

  FamilyService get _familyService => FamilyService(() => _currentUser!.token);

  /// Fetches the family member list. `relationCode` on each member is
  /// language-neutral — localize with `relationLabelFor()` at display time,
  /// reactively based on the current `LocaleProvider` locale (never bake a
  /// locale into the fetch itself, or the label goes stale when the user
  /// switches language without re-fetching).
  Future<List<FamilyMemberVm>> loadFamilyMembers() async {
    final user = _currentUser;
    if (user == null) return const [];
    if (AppConfig.mockMode) {
      return MockDataSource.membersFor(viewerId: user.userId);
    }
    return _familyService.fetchMembers(user.familyId);
  }

  Future<void> updateProfile(String name) async {
    final user = _currentUser;
    if (user == null) return;
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = user.copyWith(name: name);
    } else {
      _currentUser = await AuthService.updateMe(user, name: name);
      await AuthService.persistUser(_currentUser!);
    }
    notifyListeners();
  }

  /// Joins a different family via invite code while already logged in — see
  /// docs/api.md §3.4. The server cascades leaving the previous family
  /// (soft-delete old membership/relations, exit old group chat, transfer
  /// or clean up an orphaned admin — see TIP.md); the client just needs to
  /// swap `familyId`/`familyName`/`role` to the new family.
  ///
  /// Known mock-mode limitation: there's only ever one mock family, so this
  /// simulates success without changing any state.
  Future<void> joinAnotherFamily({
    required String inviteCode,
    required String gender,
    required int relationToMemberId,
    required String relationType,
  }) async {
    final user = _currentUser;
    if (user == null) return;
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    final joined = await _familyService.joinFamily(
      inviteCode: inviteCode,
      gender: gender,
      relationToMemberId: relationToMemberId,
      relationType: relationType,
    );
    _currentUser = user.copyWith(
      familyId: joined.familyId,
      familyName: joined.familyName,
      role: 'member',
    );
    await AuthService.persistUser(_currentUser!);
    notifyListeners();
  }

  Future<InviteCodeInfo> generateInviteCode() async {
    final user = _currentUser;
    if (user == null) throw StateError('Not authenticated');
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return InviteCodeInfo(
        inviteCode: MockDataSource.randomInviteCode(),
        expiresAt: DateTime.now().add(const Duration(hours: 48)),
      );
    }
    return _familyService.generateInviteCode(user.familyId);
  }

  Future<void> logout() async {
    final refresh = _currentUser?.refreshToken ?? '';
    _currentUser = null;
    notifyListeners();
    if (!AppConfig.mockMode) {
      await AuthService.logout(refresh);
    }
  }

  /// Called on a 401 from any authenticated request (see docs/api.md §1.3).
  /// Tries to exchange the refresh token for a new JWT before giving up —
  /// without this, any session older than the 15-minute JWT TTL would hard
  /// log out on its very next API call. Returns `true` if the session
  /// survived (caller can just retry), `false` if the caller should log out
  /// (refresh token itself expired/invalid).
  Future<bool> refreshSession() async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      final newToken = await AuthService.refresh(user.refreshToken);
      _currentUser = user.copyWith(token: newToken);
      await AuthService.persistUser(_currentUser!);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
