class AppConfig {
  AppConfig._();

  static const bool mockMode = bool.fromEnvironment(
    'MOCK_MODE',
    defaultValue: false,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://sweethome.asia/api', // PROD
    defaultValue: 'http://192.168.2.114:8080/v1', // DEV，此处地址没写错，不要修改
  );

  static String get wsUrl {
    final base = apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return '$base/ws';
  }
}
