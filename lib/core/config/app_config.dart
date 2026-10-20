class AppConfig {
  AppConfig({String? apiBaseUrl})
    : apiBaseUrl = normalizeApiBaseUrl(
        apiBaseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8080/api',
            ),
      );

  final String apiBaseUrl;

  static String normalizeApiBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    if (normalized.isEmpty) {
      return 'http://10.0.2.2:8080/api';
    }
    return normalized;
  }

  Uri endpoint(String path, [Map<String, String>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$apiBaseUrl/$cleanPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: queryParameters);
  }
}
