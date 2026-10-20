import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/core/network/api_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('envia JWT nas rotas privadas e interpreta JSON', () async {
      final mock = MockClient((request) async {
        expect(request.url.toString(), 'https://api.exemplo.com/api/dashboard');
        expect(request.headers['Authorization'], 'Bearer token-teste');
        return http.Response(
          jsonEncode({'totais': 3}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final client = ApiClient(
        config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
        tokenProvider: () => 'token-teste',
        onUnauthorized: () {},
        httpClient: mock,
      );

      final response = await client.get('dashboard') as Map<String, dynamic>;

      expect(response['totais'], 3);
      client.close();
    });

    test('não envia JWT no login e serializa o corpo', () async {
      final mock = MockClient((request) async {
        expect(request.headers['Authorization'], isNull);
        expect(jsonDecode(request.body), {
          'email': 'ana@exemplo.com',
          'senha': 'Senha123',
        });
        return http.Response(jsonEncode({'token': 'abc', 'usuario': {}}), 200);
      });
      final client = ApiClient(
        config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
        tokenProvider: () => 'nao-deve-ser-enviado',
        onUnauthorized: () {},
        httpClient: mock,
      );

      await client.post(
        'usuarios/authenticate',
        authenticated: false,
        body: {'email': 'ana@exemplo.com', 'senha': 'Senha123'},
      );

      client.close();
    });

    test('encerra a sessão e mantém a mensagem quando recebe 401', () async {
      var unauthorizedCalled = false;
      final client = ApiClient(
        config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
        tokenProvider: () => 'expirado',
        onUnauthorized: () => unauthorizedCalled = true,
        httpClient: MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Token expirado.'}), 401),
        ),
      );

      await expectLater(
        client.get('dashboard'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having((error) => error.message, 'message', 'Token expirado.'),
        ),
      );
      expect(unauthorizedCalled, isTrue);
      client.close();
    });

    test('usa o primeiro erro de validação como mensagem visível', () async {
      final client = ApiClient(
        config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
        tokenProvider: () => null,
        onUnauthorized: () {},
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': 'Dados inválidos.',
              'errors': {
                'email': ['Informe um e-mail válido.'],
              },
            }),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      try {
        await client.post('usuarios', authenticated: false, body: {});
        fail('A chamada deveria lançar ApiException.');
      } on ApiException catch (error) {
        expect(error.displayMessage, 'Informe um e-mail válido.');
      }
      client.close();
    });
  });
}
