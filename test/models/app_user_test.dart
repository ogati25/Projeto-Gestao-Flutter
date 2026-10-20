import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/models/app_user.dart';

void main() {
  test('converte usuário da API e calcula iniciais', () {
    final user = AppUser.fromJson({
      'id': 'u1',
      'nome': 'Ana',
      'sobrenome': 'Silva Santos',
      'email': 'ana@exemplo.com',
      'setor': 'TI',
      'telefone': null,
      'criadoEm': '2026-10-19T10:00:00Z',
      'atualizadoEm': null,
      'emailVerificado': true,
    });

    expect(user.fullName, 'Ana Silva Santos');
    expect(user.initials, 'AS');
    expect(user.emailVerified, isTrue);
    expect(user.toJson()['setor'], 'TI');
  });
}
