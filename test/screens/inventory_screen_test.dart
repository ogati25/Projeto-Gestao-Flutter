import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/core/network/api_exception.dart';
import 'package:gestao_ti_app/models/inventory_item.dart';
import 'package:gestao_ti_app/screens/inventory_screen.dart';
import 'package:gestao_ti_app/services/inventory_service.dart';

void main() {
  testWidgets('recarrega a categoria quando a aba volta a ficar ativa', (
    tester,
  ) async {
    final service = _CountingInventoryService();
    var active = false;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Scaffold(
              body: InventoryScreen(
                service: service,
                defaultOwner: 'Validacao Mobile',
                defaultDepartment: 'TI',
                active: active,
              ),
            );
          },
        ),
      ),
    );

    expect(service.listCalls, 0);

    updateHost(() => active = true);
    await tester.pumpAndSettle();

    expect(service.listCalls, 1);
    expect(find.text('WEB-APP-20261031'), findsOneWidget);

    updateHost(() => active = false);
    await tester.pump();
    updateHost(() => active = true);
    await tester.pumpAndSettle();

    expect(service.listCalls, 2);

    service.failNextLoad = true;
    updateHost(() => active = false);
    await tester.pump();
    updateHost(() => active = true);
    await tester.pumpAndSettle();

    expect(service.listCalls, 3);
    expect(find.text('WEB-APP-20261031'), findsOneWidget);
    expect(find.text('Falha ao atualizar o inventário.'), findsOneWidget);
  });
}

class _CountingInventoryService extends InventoryService {
  _CountingInventoryService()
    : super(
        ApiClient(
          config: AppConfig(apiBaseUrl: 'http://localhost/api'),
          tokenProvider: () => 'token-de-teste',
          onUnauthorized: () {},
        ),
      );

  int listCalls = 0;
  bool failNextLoad = false;

  @override
  Future<List<InventoryItem>> list(InventoryCategory category) async {
    listCalls++;
    if (failNextLoad) {
      failNextLoad = false;
      throw const ApiException(message: 'Falha ao atualizar o inventário.');
    }
    return [
      InventoryItem.fromJson(category, {
        'id': 'computador-1',
        'codigo': 'PC-001',
        'modelo': 'WEB-APP-20261031',
        'status': 'EmUso',
        'usuario': 'Validacao Mobile',
        'setor': 'TI',
        'ativo': true,
      }),
    ];
  }
}
