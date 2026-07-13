class LoginRequest {
  final String phone;
  final String password;
  const LoginRequest({required this.phone, required this.password});
  Map<String, dynamic> toJson() => {'phone': phone, 'password': password};
}

class RegisterRequest {
  final String name;
  final String phone;
  final String password;
  final String gender;
  final String? familyName;
  final String? inviteCode;
  final int? relationToMemberId;
  final String? relationType;

  const RegisterRequest({
    required this.name,
    required this.phone,
    required this.password,
    required this.gender,
    this.familyName,
    this.inviteCode,
    this.relationToMemberId,
    this.relationType,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
      'gender': gender,
    };
    if (familyName != null) map['familyName'] = familyName;
    if (inviteCode != null) map['inviteCode'] = inviteCode;
    if (relationToMemberId != null) map['relationToMemberId'] = relationToMemberId;
    if (relationType != null) map['relationType'] = relationType;
    return map;
  }
}

class AuthUser {
  final String token;
  final String refreshToken;
  final int userId;
  final String name;
  final String phone;
  final int familyId;
  final String familyName;
  final String role;
  final String gender;
  final String? avatarUrl;

  const AuthUser({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.name,
    required this.phone,
    required this.familyId,
    required this.familyName,
    required this.role,
    required this.gender,
    this.avatarUrl,
  });

  /// Parses the §1.1 / §1.2 register / login response envelope. Those
  /// responses do **not** include `gender` or `avatarUrl` — callers should
  /// follow up with `GET /users/me` (§2.1) to populate them, otherwise the
  /// viewer-gender-dependent kinship terms and the profile-screen avatar
  /// will fall back to defaults.
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return AuthUser(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: user['userId'] as int,
      name: user['name'] as String,
      phone: user['phone'] as String,
      familyId: user['familyId'] as int,
      familyName: user['familyName'] as String,
      role: user['role'] as String? ?? 'member',
      gender: user['gender'] as String? ?? 'male',
      avatarUrl: user['avatarUrl'] as String?,
    );
  }

  /// `GET`/`PUT /users/me` (docs/api.md §2.1/§2.2) return the flat user
  /// object without a token — reuse the caller's existing session token.
  factory AuthUser.fromUserFields(
    Map<String, dynamic> user, {
    required String token,
    required String refreshToken,
  }) {
    return AuthUser(
      token: token,
      refreshToken: refreshToken,
      userId: user['userId'] as int,
      name: user['name'] as String,
      phone: user['phone'] as String,
      familyId: user['familyId'] as int,
      familyName: user['familyName'] as String,
      role: user['role'] as String? ?? 'member',
      gender: user['gender'] as String? ?? 'male',
      avatarUrl: user['avatarUrl'] as String?,
    );
  }

  AuthUser copyWith({
    String? token,
    String? name,
    int? familyId,
    String? familyName,
    String? role,
    String? gender,
    String? avatarUrl,
  }) =>
      AuthUser(
        token: token ?? this.token,
        refreshToken: refreshToken,
        userId: userId,
        name: name ?? this.name,
        phone: phone,
        familyId: familyId ?? this.familyId,
        familyName: familyName ?? this.familyName,
        role: role ?? this.role,
        gender: gender ?? this.gender,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, String> toPrefs() => {
        'token': token,
        'refreshToken': refreshToken,
        'userId': userId.toString(),
        'name': name,
        'phone': phone,
        'familyId': familyId.toString(),
        'familyName': familyName,
        'role': role,
        'gender': gender,
        // ignore: use_null_aware_elements
        if (avatarUrl != null) 'avatarUrl': avatarUrl!,
      };

  static AuthUser? fromPrefs(Map<String, String?> prefs) {
    if (prefs['token'] == null || prefs['userId'] == null) return null;
    return AuthUser(
      token: prefs['token']!,
      refreshToken: prefs['refreshToken'] ?? '',
      userId: int.parse(prefs['userId']!),
      name: prefs['name'] ?? '',
      phone: prefs['phone'] ?? '',
      familyId: int.parse(prefs['familyId'] ?? '0'),
      familyName: prefs['familyName'] ?? '',
      role: prefs['role'] ?? 'member',
      gender: prefs['gender'] ?? 'male',
      avatarUrl: prefs['avatarUrl'],
    );
  }
}
