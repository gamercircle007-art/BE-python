/// Environment-based application configuration.
///
/// Override at build time:
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
/// flutter run --dart-define=APP_ENV=dev
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
  });

  final String apiBaseUrl;
  final String environment;

  static const AppConfig instance = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000/api/v1',
    ),
    environment: String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'local',
    ),
  );

  bool get isProduction => environment == 'prod';
  bool get isLocal => environment == 'local';
}