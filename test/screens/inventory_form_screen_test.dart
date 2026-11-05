import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/models/inventory_item.dart';
import 'package:gestao_ti_app/screens/inventory_form_screen.dart';
import 'package:gestao_ti_app/services/inventory_service.dart';

void main() {
  testWidgets('formulario de computador renderiza campos multilinha', (
    tester,
  ) async {
    final apiClient = ApiClient(
      config: AppConfig(apiBaseUrl: 'http://localhost/api'),
      tokenProvider: () => 'token-de-teste',
      onUnauthorized: () {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventoryFormScreen(
          service: InventoryService(apiClient),
          category: InventoryCategory.computers,
          defaultOwner: 'Validacao Mobile',
          defaultDepartment: 'TI',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Novo computador'), findsWidgets);

    apiClient.close();
  });
}
