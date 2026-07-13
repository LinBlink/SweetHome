class AppConfig {
  AppConfig._();

  static const bool mockMode = bool.fromEnvironment(
    'MOCK_MODE',
    defaultValue: false,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://sweethome.asia/api', // PROD
    defaultValue: 'http://127.0.0.1:8080/v1',
  );

  static String get wsUrl {
    final base = apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return '$base/ws';
  }
}
