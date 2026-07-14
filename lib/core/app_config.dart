class AppConfig {
  AppConfig._();

  static const bool mockMode = bool.fromEnvironment(
    'MOCK_MODE',
    defaultValue: false,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://sweethome.asia/api', // PROD
    defaultValue: 'http://192.168.2.114:8080/api/v1', // DEV
  );

  static String get wsUrl {
    final base = apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return '$base/ws';
  }
}
