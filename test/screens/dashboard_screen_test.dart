import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/core/config/app_config.dart';
import 'package:gestao_ti_app/core/network/api_client.dart';
import 'package:gestao_ti_app/core/network/api_exception.dart';
import 'package:gestao_ti_app/models/app_user.dart';
import 'package:gestao_ti_app/models/dashboard_summary.dart';
import 'package:gestao_ti_app/screens/dashboard_screen.dart';
import 'package:gestao_ti_app/services/dashboard_service.dart';

void main() {
  testWidgets('recarrega o resumo quando a aba volta a ficar ativa', (
    tester,
  ) async {
    final service = _CountingDashboardService();
    var active = false;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Scaffold(
              body: DashboardScreen(
                service: service,
                user: const AppUser(
                  id: 'usuario-1',
                  firstName: 'Validacao',
                  lastName: 'Mobile',
                  email: 'validacao@example.test',
                  department: 'TI',
                  emailVerified: true,
                ),
                active: active,
              ),
            );
          },
        ),
      ),
    );

    expect(service.loadCalls, 0);

    updateHost(() => active = true);
    await tester.pumpAndSettle();

    expect(service.loadCalls, 1);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Itens ativos'), findsOneWidget);

    updateHost(() => active = false);
    await tester.pump();
    updateHost(() => active = true);
    await tester.pumpAndSettle();

    expect(service.loadCalls, 2);

    service.failNextLoad = true;
    updateHost(() => active = false);
    await tester.pump();
    updateHost(() => active = true);
    await tester.pumpAndSettle();

    expect(service.loadCalls, 3);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Falha ao atualizar o dashboard.'), findsOneWidget);
  });
}

class _CountingDashboardService extends DashboardService {
  _CountingDashboardService()
    : super(
        ApiClient(
          config: AppConfig(apiBaseUrl: 'http://localhost/api'),
          tokenProvider: () => 'token-de-teste',
          onUnauthorized: () {},
        ),
      );

  int loadCalls = 0;
  bool failNextLoad = false;

  @override
  Future<DashboardSummary> loadSummary() async {
    loadCalls++;
    if (failNextLoad) {
      failNextLoad = false;
      throw const ApiException(message: 'Falha ao atualizar o dashboard.');
    }
    return DashboardSummary.fromJson({
      'totais': {'total': 1, 'computadores': 1},
      'manutencao': {'total': 0},
      'distribuicao': {
        'categorias': [
          {'nome': 'Computadores', 'quantidade': 1, 'percentual': 100},
        ],
      },
      'ocupacao': {
        'categorias': [
          {
            'nome': 'Computadores',
            'ativos': 1,
            'inativos': 0,
            'total': 1,
            'percentual': 100,
          },
        ],
      },
      'itensCriticos': {'itens': <Object>[]},
      'atividades': {'atividades': <Object>[]},
    });
  }
}
