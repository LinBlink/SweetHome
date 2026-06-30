class AppConfig {
  AppConfig._();

  static const bool mockMode = bool.fromEnvironment(
    'MOCK_MODE',
    defaultValue: false,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static String get wsUrl {
    final base = apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return '$base/ws';
  }
}
