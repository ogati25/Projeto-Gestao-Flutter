import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('remove barras finais da URL', () {
      final config = AppConfig(apiBaseUrl: 'http://10.0.2.2:8080/api///');
      expect(config.apiBaseUrl, 'http://10.0.2.2:8080/api');
      expect(
        config.endpoint('/dashboard').toString(),
        'http://10.0.2.2:8080/api/dashboard',
      );
    });

    test('adiciona query parameters', () {
      final config = AppConfig(apiBaseUrl: 'https://api.exemplo.com/api');
      expect(
        config.endpoint('dashboard/criticos', {'limite': '10'}).toString(),
        'https://api.exemplo.com/api/dashboard/criticos?limite=10',
      );
    });
  });
}
