class ApiConstants {
  // Local dev uses the default. Production builds override via:
  // flutter build web --dart-define=API_BASE_URL=https://...railway.app
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}