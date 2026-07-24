import 'dart:async';

import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import '../core/error_messages.dart';
import '../core/kinship/kinship_graph.dart';
import '../data/mock_data.dart';
import '../models/api_exception.dart';
import '../models/auth_models.dart';
import '../models/family_member_vm.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/push_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = true;
  String? _error;

  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  /// Injected at construction time from `main.dart` — the same singleton
  /// also wired up at app startup (see `PushService.setup`). `null` is
  /// allowed (e.g. tests / web) and degrades push registration/deregistration
  /// to no-ops.
  final PushService? _push;

  /// Exposes the injected [PushService] so `main.dart` can wire up
  /// [PushNotificationRouter] without reaching into a private field
  /// across library boundaries.
  PushService? get pushService => _push;

  AuthProvider({PushService? push}) : _push = push {
    // One AuthProvider per app run (created once at root in main.dart)
    // — self-register so *any* service call anywhere that routes
    // through ApiClient.unwrap and hits a 401 flows through the same
    // refresh-or-logout handling as ChatProvider's existing 401 path,
    // without every provider/screen needing its own bespoke wiring.
    ApiClient.onUnauthorized = () => unawaited(handleUnauthorized());
    _restoreSession();
  }

  Timer? _refreshTimer;

  /// The JWT TTL is 15 minutes (docs/api.md §1.2). Reactive refresh-on-401
  /// (`handleUnauthorized`) covers REST calls fine, but the WebSocket
  /// connection has no equivalent signal: `WebSocketService` reconnects
  /// using whatever token `tokenProvider()` currently returns, and a
  /// handshake rejected for an expired JWT looks identical to a plain
  /// network failure — it just backs off and retries with the same stale
  /// token, with no path back to this provider. A socket that drops after
  /// expiry with no REST call happening nearby to trigger a reactive
  /// refresh would otherwise never recover. Refreshing proactively, well
  /// inside the 15-minute window, keeps the token that `WebSocketService`
  /// reads always fresh so reconnects never race an expiry.
  static const _refreshInterval = Duration(minutes: 10);

  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(handleUnauthorized()),
    );
  }

  void _cancelTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _cancelTokenRefresh();
    super.dispose();
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
    }
    // Best-effort: refresh from /users/me so persisted-but-stale fields
    // (gender, avatarUrl) catch up if a previous session left them empty.
    if (_currentUser != null) {
      try {
        final fresh = await AuthService.fetchMe(_currentUser!);
        _currentUser = fresh;
        await AuthService.persistUser(_currentUser!);
      } catch (_) {}
      // Re-bind push for the restored session — we can't be sure
      // the last `logout()` actually reached the server (a crashed
      // app would skip it), so calling `registerForUser` again with
      // the restored token is safe (the server upserts by token,
      // see §2.7.1).
      unawaited(_push?.registerForUser(_currentUser!));
      _scheduleTokenRefresh();
    }
    _isLoading = false;
    notifyListeners();
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
        _currentUser = await AuthService.login(
          LoginRequest(phone: phone, password: password),
        );
        // The §1.2 login response omits `gender` and `avatarUrl`; follow up
        // with §2.1 to populate them so kinship localization (S.F#male vs
        // S.F#female) and the profile-screen avatar render correctly. A
        // failure here is non-fatal — the user is already authenticated.
        try {
          final fresh = await AuthService.fetchMe(_currentUser!);
          _currentUser = fresh;
          await AuthService.persistUser(_currentUser!);
        } catch (_) {}
        // §2.7.1: register this device's JPush registration ID with
        // the new session so fence-alarm pushes can be delivered.
        unawaited(_push?.registerForUser(_currentUser!));
        _scheduleTokenRefresh();
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
        // §1.1 register response omits `gender`/`avatarUrl`; follow up with
        // §2.1 (best-effort, just like login above).
        try {
          final fresh = await AuthService.fetchMe(_currentUser!);
          _currentUser = fresh;
          await AuthService.persistUser(_currentUser!);
        } catch (_) {}
        // §2.7.1: same as login — register the JPush token with the
        // freshly-minted session.
        unawaited(_push?.registerForUser(_currentUser!));
        _scheduleTokenRefresh();
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
  ///
  /// Side effect: caches each member's `gender` by both `userId` (see
  /// [genderForUserId]) and `name` (see [genderForName]) — the
  /// conversation-list's spouse label needs a gender to pick "丈夫" vs
  /// "妻子" for the bare `S` relation code, but the conversation
  /// payload's own `otherUserGender` (and, confirmed against a real
  /// backend response, sometimes even `otherUserId`) isn't reliably
  /// populated. `family_members`' `gender` always has a real value (see
  /// `FamilyMemberVm.gender`, never null), so it's used as the
  /// fallback — by `userId` when available, or by `name` (a direct
  /// conversation's `name` is the other participant's display name,
  /// per docs/api.md §4.1) when `otherUserId` itself is missing too.
  /// Name matching is a last resort — it'll misfire if two family
  /// members share an identical display name — but it's strictly
  /// better than showing no relation label at all. Any caller of this
  /// method — contacts screen, family tree, etc. — warms both caches
  /// as a side effect, so the fallback works regardless of which
  /// screen the user happened to visit first.
  Future<List<FamilyMemberVm>> loadFamilyMembers() async {
    final user = _currentUser;
    if (user == null) return const [];
    final members = AppConfig.mockMode
        ? MockDataSource.membersFor(viewerId: user.userId)
        : await _familyService.fetchMembers(user.familyId);
    var changed = false;
    for (final m in members) {
      if (_memberGenderByUserId[m.userId] != m.gender) {
        _memberGenderByUserId[m.userId] = m.gender;
        changed = true;
      }
      if (_memberGenderByName[m.name] != m.gender) {
        _memberGenderByName[m.name] = m.gender;
        changed = true;
      }
    }
    if (changed) notifyListeners();
    return members;
  }

  final Map<int, Gender> _memberGenderByUserId = {};
  final Map<String, Gender> _memberGenderByName = {};

  /// See [loadFamilyMembers]'s doc comment — fallback gender source for
  /// `Conversation.otherUserGender` when that field comes back null.
  Gender? genderForUserId(int userId) => _memberGenderByUserId[userId];

  /// See [loadFamilyMembers]'s doc comment — last-resort fallback for
  /// when `otherUserId` itself is also missing, keyed by display name
  /// instead.
  Gender? genderForName(String name) => _memberGenderByName[name];

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

  /// `POST /users/upload/avatar` (docs/api.md §2.3). The [bytes] should be
  /// the picked file's content; [filename] is forwarded as the multipart
  /// part's filename and [contentType] as the part's Content-Type header
  /// (the backend's `UploadServiceImpl` reads `getContentType()` to
  /// enforce its `image/*` rule — passing it explicitly is the only way
  /// to guarantee that check sees a real `image/...` MIME, regardless of
  /// what the `http` package would otherwise infer from the filename).
  /// On success the local [AuthUser]'s `avatarUrl` is updated and
  /// persisted, and the new URL is returned.
  ///
  /// In mock mode there's no backend to upload to, so we synthesize a
  /// fake URL to drive the same UI path.
  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final user = _currentUser;
    if (user == null) return null;
    if (AppConfig.mockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final fakeUrl =
          'https://mock.local/avatars/${user.userId}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      _currentUser = user.copyWith(avatarUrl: fakeUrl);
      await AuthService.persistUser(_currentUser!);
      notifyListeners();
      return fakeUrl;
    }
    final url = await AuthService.uploadAvatar(
      user,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    _currentUser = user.copyWith(avatarUrl: url);
    await AuthService.persistUser(_currentUser!);
    notifyListeners();
    return url;
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
    final user = _currentUser;
    final refresh = user?.refreshToken ?? '';
    _currentUser = null;
    _cancelTokenRefresh();
    notifyListeners();
    // §2.7.2: deregister the JPush token BEFORE wiping local credentials
    // — the call needs the live JWT in its Authorization header. Wait
    // for it (with a short timeout via the service's internal clock)
    // before clearing local state, so a deregister-in-flight failure
    // can't leak the user's push targets to the next login.
    if (user != null) {
      await _push?.deregisterForUser(user);
    }
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

  Future<bool>? _unauthorizedHandling;

  /// Single entry point for "a request came back 401" from anywhere in
  /// the app — [ApiClient.onUnauthorized] (registered in the
  /// constructor above) calls this for every service that routes
  /// through [ApiClient.unwrap], and [ChatProvider]'s own 401 path
  /// (wired in `main.dart`) calls it too so both share one in-flight
  /// refresh instead of racing separate `refreshSession()` calls when
  /// several requests hit 401 around the same time (e.g. a batch of
  /// chat + location + family calls all firing right as the JWT
  /// expires). Memoizes the in-flight `Future` synchronously (`??=`,
  /// before any `await`), so re-entrant calls made in the same event
  /// as the first — including one that might come from *inside*
  /// `refreshSession()` itself, if the refresh-token call also 401s —
  /// just await the same result instead of starting a second refresh
  /// or double-logging-out.
  Future<bool> handleUnauthorized() {
    return _unauthorizedHandling ??= _doHandleUnauthorized();
  }

  Future<bool> _doHandleUnauthorized() async {
    try {
      if (!isAuthenticated) return false;
      final ok = await refreshSession();
      if (!ok) await logout();
      return ok;
    } finally {
      _unauthorizedHandling = null;
    }
  }

  /// §2.1 — refetch the current user. Used by the §9 red-packet send
  /// flow to surface the new `balance` (the §9.1 response doesn't echo
  /// it back). Returns `false` on any failure (silently swallowed —
  /// the optimistic UI keeps the pre-send balance, and the next
  /// session restore will pick up the truth from the server). The
  /// `MockDataSource` doesn't override this path because mock mode
  /// never actually deducts anything from the user's balance.
  Future<bool> refreshBalance() async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      final fresh = await AuthService.fetchMe(user);
      _currentUser = fresh;
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
