import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_ti_app/models/inventory_form_schema.dart';
import 'package:gestao_ti_app/models/inventory_item.dart';

void main() {
  group('InventoryPayloadBuilder.build', () {
    test(
      'monta os campos comuns, converte decimal com virgula e omite ids',
      () {
        final payload = InventoryPayloadBuilder.build(
          category: InventoryCategory.mice,
          owner: '  Ana Silva  ',
          acquisitionDate: DateTime(2026, 10, 25, 18, 30),
          acquisitionPrice: '1250,50',
          active: true,
          department: '  TI  ',
          status: '  EmUso  ',
          observations: '   ',
          inputs: const {
            'modelo': '  Logitech M170  ',
            'tipo': '  Optico  ',
            'conectividade': '  Sem fio  ',
          },
          toggles: const {},
          existingRaw: const {'id': 'mouse-1', 'codigo': 'MOU001'},
        );

        expect(payload['usuario'], 'Ana Silva');
        expect(payload['dataAquisicao'], '2026-10-25T00:00:00.000Z');
        expect(payload['precoAquisicao'], 1250.50);
        expect(payload['ativo'], isTrue);
        expect(payload['setor'], 'TI');
        expect(payload['status'], 'EmUso');
        expect(payload['observacoes'], isNull);
        expect(payload['modelo'], 'Logitech M170');
        expect(payload['tipo'], 'Optico');
        expect(payload['conectividade'], 'Sem fio');
        expect(payload.containsKey('id'), isFalse);
        expect(payload.containsKey('codigo'), isFalse);
      },
    );

    test('normaliza computador, calcula totais e preserva processador', () {
      final payload = InventoryPayloadBuilder.build(
        category: InventoryCategory.computers,
        owner: 'Ana',
        acquisitionDate: DateTime(2026, 10, 25),
        acquisitionPrice: '4500',
        active: true,
        department: 'TI',
        status: 'EmUso',
        observations: 'Estacao principal',
        inputs: const {
          'modelo': 'Dell OptiPlex',
          'tipo': 'Desktop',
          'geracaoRAM': 'DDR4',
          'memoriaRAM': '8, 16',
          'velocidadeRAM': '3200',
          'discos': 'SSD:512; HDD:1000',
          'placasVideo': 'RTX 3060:12',
          'conectoresVideo': 'HDMI, DisplayPort, HDMI',
          'sistemaOperacional': 'Windows 11',
          'ativacaoSO': 'Ativado',
          'office': 'Microsoft 365',
          'ativacaoOffice': 'Ativado',
          'ip': '192.168.1.20',
        },
        toggles: const {},
        existingRaw: const {
          'id': 'computer-1',
          'codigo': 'COM001',
          'processador': {'id': 'processor-1', 'nome': 'Core i5'},
        },
      );

      expect(payload['processadorId'], 'processor-1');
      expect(payload.containsKey('processador'), isFalse);
      expect(payload['memoriaRAM'], [8, 16]);
      expect(payload['quantidadeSlots'], 2);
      expect(payload['memoriaRAMTotal'], 24);
      expect(payload['velocidadeRAM'], 3200);
      expect(payload['discos'], [
        {'tipo': 'SSD', 'tamanho': 512},
        {'tipo': 'HDD', 'tamanho': 1000},
      ]);
      expect(payload['quantidadeDiscos'], 2);
      expect(payload['placasVideo'], [
        {'tipo': 'RTX 3060', 'vram': 12},
      ]);
      expect(payload['quantidadePlacasVideo'], 1);
      expect(payload['conectoresVideo'], ['HDMI', 'DisplayPort']);
      expect(payload['quantidadeConectoresVideo'], 2);
    });

    test('preserva ids de chips e contas de WhatsApp ao editar celular', () {
      final payload = InventoryPayloadBuilder.build(
        category: InventoryCategory.phones,
        owner: 'Ana',
        acquisitionDate: DateTime(2026, 10, 25),
        acquisitionPrice: '1800',
        active: true,
        department: 'Comercial',
        status: 'EmUso',
        observations: '',
        inputs: const {
          'modelo': 'Galaxy A54',
          'memoriaRAM': '8',
          'armazenamento': '128',
          'conectividade': 'USB-C',
        },
        toggles: const {},
        existingRaw: const {
          'id': 'phone-1',
          'chipIds': ['chip-1', 'chip-2', 'chip-1'],
          'contasWhatsapp': [
            {'id': 'chip-2'},
            {'id': 'chip-3'},
          ],
        },
      );

      expect(payload['chipIds'], ['chip-1', 'chip-2']);
      expect(payload['contasWhatsapp'], ['chip-2', 'chip-3']);
      expect(payload['memoriaRAM'], 8);
      expect(payload['armazenamento'], 128);
      expect(payload.containsKey('chips'), isFalse);
    });

    test('rejeita preco de aquisicao negativo', () {
      expect(
        () => InventoryPayloadBuilder.build(
          category: InventoryCategory.extras,
          owner: 'Ana',
          acquisitionDate: DateTime(2026, 10, 25),
          acquisitionPrice: '-1',
          active: true,
          department: 'TI',
          status: 'EmEstoque',
          observations: '',
          inputs: const {'categoria': 'Adaptadores', 'quantidade': '1'},
          toggles: const {},
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('não pode ser negativo'),
          ),
        ),
      );
    });
  });

  group('InventoryPayloadBuilder.validateField', () {
    InventoryFieldSpec field(InventoryCategory category, String key) {
      return inventoryFieldsFor(category)
          .singleWhere((item) => item.key == key);
    }

    test('valida numero de chip nos dois formatos aceitos', () {
      final number = field(InventoryCategory.simCards, 'numero');

      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.simCards,
          number,
          '(11) 9999-1234',
        ),
        isNull,
      );
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.simCards,
          number,
          '(11) 99999-1234',
        ),
        isNull,
      );
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.simCards,
          number,
          '+55 11 99999-1234',
        ),
        contains('(XX)'),
      );
    });

    test('exige os identificadores principais de cada categoria', () {
      for (final category in InventoryCategory.values) {
        final requiredFields = inventoryFieldsFor(category)
            .where((item) => item.required);

        for (final requiredField in requiredFields) {
          expect(
            InventoryPayloadBuilder.validateField(
              category,
              requiredField,
              '   ',
            ),
            isNotNull,
            reason: '${category.name}/${requiredField.key}',
          );
        }
      }
    });

    test('aplica limites numericos e limites de listas do computador', () {
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.monitors,
          field(InventoryCategory.monitors, 'tamanho'),
          '100,1',
        ),
        contains('máximo 100'),
      );
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.keyboards,
          field(InventoryCategory.keyboards, 'tamanho'),
          '-1',
        ),
        contains('negativo'),
      );
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.computers,
          field(InventoryCategory.computers, 'placasVideo'),
          'A:1; B:2; C:3; D:4; E:5; F:6',
        ),
        contains('máximo 5 itens'),
      );
    });

    test('rejeita numeros e pares malformados', () {
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.phones,
          field(InventoryCategory.phones, 'memoriaRAM'),
          'oito',
        ),
        contains('número inteiro'),
      );
      expect(
        InventoryPayloadBuilder.validateField(
          InventoryCategory.computers,
          field(InventoryCategory.computers, 'discos'),
          'SSD 512',
        ),
        contains('Tipo:valor'),
      );
    });
  });
}
