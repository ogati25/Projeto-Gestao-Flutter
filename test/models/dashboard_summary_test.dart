import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/models/dashboard_summary.dart';

void main() {
  test('interpreta resumo completo e alias legado de manutenção', () {
    final summary = DashboardSummary.fromJson({
      'totais': {'total': 4, 'computadores': 2, 'monitores': 1, 'celulares': 1},
      'baixoEstoque': {'total': 1, 'computadores': 1},
      'distribuicao': {
        'categorias': [
          {'nome': 'Computadores', 'quantidade': 2, 'percentual': 50.0},
        ],
      },
      'ocupacao': {
        'categorias': [
          {
            'nome': 'Computadores',
            'ativos': 1,
            'inativos': 1,
            'total': 2,
            'percentual': 50,
          },
        ],
      },
      'itensCriticos': {'itens': <Object>[]},
      'atividades': {'atividades': <Object>[]},
    });

    expect(summary.totals.total, 4);
    expect(summary.maintenance.total, 1);
    expect(summary.distribution.single.quantity, 2);
    expect(summary.activeTotal, 1);
  });
}
