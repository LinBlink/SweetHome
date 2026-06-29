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
  final String familyName;
  const RegisterRequest({required this.name, required this.phone, required this.password, required this.familyName});
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone, 'password': password, 'familyName': familyName};
}

class AuthUser {
  final String token;
  final int userId;
  final String name;
  final String phone;
  final int familyId;
  final String familyName;
  final String role;

  AuthUser({required this.token, required this.userId, required this.name, required this.phone, required this.familyId, required this.familyName, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        token: json['token'] as String,
        userId: json['userId'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String,
        familyId: json['familyId'] as int,
        familyName: json['familyName'] as String,
        role: json['role'] as String,
      );
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
