import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/models/inventory_item.dart';

void main() {
  test('usa número como título de chip e indexa campos para busca', () {
    final item = InventoryItem.fromJson(InventoryCategory.simCards, {
      'id': '1',
      'codigo': 'CHP001',
      'numero': '(11) 99999-0000',
      'operadora': 'Exemplo',
      'usuario': 'Ana',
      'setor': 'TI',
      'status': 'Em uso',
      'ativo': true,
    });

    expect(item.title, '(11) 99999-0000');
    expect(item.searchableText, contains('chp001'));
    expect(item.searchableText, contains('exemplo'));
  });

  test('usa descrição como título de extra', () {
    final item = InventoryItem.fromJson(InventoryCategory.extras, {
      'descricao': 'Adaptador USB-C',
      'categoria': 'Adaptadores',
    });

    expect(item.title, 'Adaptador USB-C');
  });
}
