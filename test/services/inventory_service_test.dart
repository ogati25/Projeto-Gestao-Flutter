import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/core/network/api_exception.dart';
import 'package:gestao_ti_app/models/inventory_item.dart';
import 'package:gestao_ti_app/services/inventory_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('InventoryService', () {
    test(
      'lista a categoria pela rota autenticada e converte os itens',
      () async {
        final harness = _serviceWith((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/monitores');
          expect(request.headers['Authorization'], 'Bearer token-inventario');
          expect(request.headers['Accept'], 'application/json');

          return _jsonResponse([
            {
              'id': 'monitor-1',
              'codigo': 'MON-001',
              'modelo': 'Dell P2422H',
              'status': 'EmUso',
              'usuario': 'Ana Silva',
              'setor': 'TI',
              'ativo': true,
            },
          ]);
        });

        final items = await harness.service.list(InventoryCategory.monitors);

        expect(items, hasLength(1));
        expect(items.single.id, 'monitor-1');
        expect(items.single.code, 'MON-001');
        expect(items.single.title, 'Dell P2422H');
        expect(items.single.category, InventoryCategory.monitors);
        harness.client.close();
      },
    );

    test('cria item com POST, JWT e JSON no contrato esperado', () async {
      final payload = <String, dynamic>{
        'usuario': 'Ana Silva',
        'dataAquisicao': '2026-10-25T00:00:00.000',
        'precoAquisicao': 1299.90,
        'ativo': true,
        'setor': 'TI',
        'status': 'EmEstoque',
        'observacoes': null,
        'modelo': 'Logitech M170',
        'tipo': 'Óptico',
        'conectividade': 'Sem fio',
      };
      final harness = _serviceWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/mouses');
        expect(request.headers['Authorization'], 'Bearer token-inventario');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(jsonDecode(request.body), payload);

        return _jsonResponse({
          'id': 'mouse-1',
          'codigo': 'MOU-001',
          ...payload,
        }, statusCode: 201);
      });

      final created = await harness.service.create(
        InventoryCategory.mice,
        payload,
      );

      expect(created.id, 'mouse-1');
      expect(created.code, 'MOU-001');
      expect(created.title, 'Logitech M170');
      expect(created.category, InventoryCategory.mice);
      harness.client.close();
    });

    test(
      'atualiza item completo com PUT e aceita resposta 204 vazia',
      () async {
        final payload = <String, dynamic>{
          'usuario': 'Carlos Souza',
          'dataAquisicao': '2026-10-20T00:00:00.000',
          'precoAquisicao': 349.50,
          'ativo': false,
          'setor': 'Financeiro',
          'status': 'EmManutenção',
          'observacoes': 'Aguardando reparo.',
          'modelo': 'Jabra Evolve 20',
          'tipo': 'Headset',
          'microfone': true,
          'conectividade': 'USB',
        };
        final harness = _serviceWith((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/fones/fone-1');
          expect(request.headers['Authorization'], 'Bearer token-inventario');
          expect(request.headers['Content-Type'], contains('application/json'));
          expect(jsonDecode(request.body), payload);
          return http.Response('', 204);
        });

        await harness.service.update(
          InventoryCategory.headsets,
          'fone-1',
          payload,
        );

        harness.client.close();
      },
    );

    test('exclui item com DELETE autenticado e aceita resposta 204', () async {
      final harness = _serviceWith((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/extras/extra-1');
        expect(request.headers['Authorization'], 'Bearer token-inventario');
        expect(request.body, isEmpty);
        return http.Response('', 204);
      });

      await harness.service.delete(InventoryCategory.extras, 'extra-1');

      harness.client.close();
    });

    test('propaga conflito 409 com a mensagem retornada pela API', () async {
      final harness = _serviceWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/chips');
        return _jsonResponse({
          'message': 'O celular já possui dois chips.',
        }, statusCode: 409);
      });

      await expectLater(
        harness.service.create(InventoryCategory.simCards, {
          'numero': '(11) 99999-1234',
        }),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 409)
              .having(
                (error) => error.displayMessage,
                'displayMessage',
                'O celular já possui dois chips.',
              ),
        ),
      );

      harness.client.close();
    });

    test('rejeita update e delete quando o identificador esta vazio', () async {
      var requestCount = 0;
      final harness = _serviceWith((request) async {
        requestCount++;
        return http.Response('', 204);
      });

      await expectLater(
        harness.service.update(InventoryCategory.computers, '', const {}),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        harness.service.delete(InventoryCategory.computers, ''),
        throwsA(isA<FormatException>()),
      );
      expect(requestCount, 0);
      harness.client.close();
    });
  });
}

_InventoryHarness _serviceWith(MockClientHandler handler) {
  final client = ApiClient(
    config: AppConfig(apiBaseUrl: 'https://api.exemplo.com/api'),
    tokenProvider: () => 'token-inventario',
    onUnauthorized: () {},
    httpClient: MockClient(handler),
  );
  return _InventoryHarness(client, InventoryService(client));
}

http.Response _jsonResponse(Object body, {int statusCode = 200}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _InventoryHarness {
  const _InventoryHarness(this.client, this.service);

  final ApiClient client;
  final InventoryService service;
}
