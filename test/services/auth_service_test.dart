import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthService', () {
    test('carrega setores públicos ordenados e sem duplicação', () async {
      final service = _serviceWith((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/opcoes/Setor');
        expect(request.headers['Authorization'], isNull);
        return _jsonResponse(['Vendas', 'TI', 'TI']);
      });

      expect(await service.loadDepartments(), ['TI', 'Vendas']);
    });

    test('cadastra usuário com o contrato esperado', () async {
      final service = _serviceWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/usuarios');
        expect(jsonDecode(request.body), {
          'nome': 'Ana',
          'sobrenome': 'Silva',
          'email': 'ana@exemplo.com',
          'setor': 'TI',
          'telefone': null,
          'senha': 'Senha123',
        });
        return _jsonResponse({
          'id': 'usuario-1',
          'nome': 'Ana',
          'sobrenome': 'Silva',
          'email': 'ana@exemplo.com',
          'setor': 'TI',
          'telefone': null,
          'emailVerificado': false,
        }, statusCode: 201);
      });

      final user = await service.register(
        firstName: ' Ana ',
        lastName: ' Silva ',
        email: ' ana@exemplo.com ',
        department: 'TI',
        phone: '',
        password: 'Senha123',
      );

      expect(user.id, 'usuario-1');
      expect(user.emailVerified, isFalse);
    });

    test('confirma e reenvia código pelas rotas públicas', () async {
      final requests = <http.Request>[];
      final service = _serviceWith((request) async {
        requests.add(request);
        return _jsonResponse({'message': 'Operação concluída.'});
      });

      await service.confirmEmail('123456');
      await service.resendVerification('usuario-1');

      expect(requests[0].url.path, '/api/usuarios/confirmar-email');
      expect(jsonDecode(requests[0].body), {'token': '123456'});
      expect(
        requests[1].url.path,
        '/api/usuarios/usuario-1/enviar-verificacao',
      );
      expect(
        requests.every((request) => request.headers['Authorization'] == null),
        isTrue,
      );
    });

    test('solicita e aplica redefinição de senha', () async {
      final requests = <http.Request>[];
      final service = _serviceWith((request) async {
        requests.add(request);
        return _jsonResponse({'message': 'Tudo certo.'});
      });

      await service.requestPasswordReset('ana@exemplo.com');
      await service.resetPassword(
        token: 'token-seguro',
        newPassword: 'NovaSenha123',
      );

      expect(requests[0].url.path, '/api/usuarios/recuperar-senha');
      expect(jsonDecode(requests[0].body), {'email': 'ana@exemplo.com'});
      expect(requests[1].url.path, '/api/usuarios/redefinir-senha');
      expect(jsonDecode(requests[1].body), {
        'token': 'token-seguro',
        'novaSenha': 'NovaSenha123',
      });
    });
  });
}

AuthService _serviceWith(MockClientHandler handler) {
  final client = ApiClient(
    config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
    tokenProvider: () => 'token-que-nao-deve-ser-usado',
    onUnauthorized: () {},
    httpClient: MockClient(handler),
  );
  return AuthService(client);
}

http.Response _jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
