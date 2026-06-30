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
  final String? familyName;
  final String? inviteCode;

  const RegisterRequest({
    required this.name,
    required this.phone,
    required this.password,
    this.familyName,
    this.inviteCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'phone': phone,
      'password': password,
    };
    if (familyName != null) map['familyName'] = familyName;
    if (inviteCode != null) map['inviteCode'] = inviteCode;
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

  const AuthUser({
    required this.token,
    required this.refreshToken,
    required this.userId,
    required this.name,
    required this.phone,
    required this.familyId,
    required this.familyName,
    required this.role,
  });

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
    );
  }

  Map<String, String> toPrefs() => {
        'token': token,
        'refreshToken': refreshToken,
        'userId': userId.toString(),
        'name': name,
        'phone': phone,
        'familyId': familyId.toString(),
        'familyName': familyName,
        'role': role,
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
    );
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
