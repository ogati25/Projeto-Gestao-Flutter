import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/core/storage/session_storage.dart';
import 'package:gestao_ti_app/models/app_user.dart';
import 'package:gestao_ti_app/screens/home_shell.dart';
import 'package:gestao_ti_app/services/auth_service.dart';
import 'package:gestao_ti_app/services/dashboard_service.dart';
import 'package:gestao_ti_app/services/inventory_service.dart';
import 'package:gestao_ti_app/state/session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('botao do perfil expoe somente um rotulo descritivo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final apiClient = ApiClient(
      config: AppConfig(apiBaseUrl: 'http://localhost/api'),
      tokenProvider: () => 'token-de-teste',
      onUnauthorized: () {},
      httpClient: MockClient(
        (_) async => http.Response(
          '{"totais":{"total":0},"manutencao":{"total":0},'
          '"distribuicao":{"categorias":[]},'
          '"ocupacao":{"categorias":[]},'
          '"itensCriticos":{"itens":[]},'
          '"atividades":{"atividades":[]}}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final sessionController = SessionController(
      storage: _MemorySessionStorage(),
      authService: AuthService(apiClient),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          user: const AppUser(
            id: 'usuario-1',
            firstName: 'Validacao',
            lastName: 'Mobile',
            email: 'validacao@example.test',
            department: 'TI',
            emailVerified: true,
          ),
          sessionController: sessionController,
          dashboardService: DashboardService(apiClient),
          inventoryService: InventoryService(apiClient),
          config: AppConfig(apiBaseUrl: 'http://localhost/api'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final profileButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Meu perfil',
    );
    expect(profileButton, findsOneWidget);
    expect(find.bySemanticsLabel('Meu perfil'), findsOneWidget);
    expect(find.bySemanticsLabel('VM'), findsNothing);

    apiClient.close();
    semantics.dispose();
  });
}

class _MemorySessionStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<String?> readUserJson() async => null;

  @override
  Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {}
}
