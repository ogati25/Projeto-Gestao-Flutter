import 'inventory_item.dart';

enum InventoryFieldKind {
  text,
  select,
  processorSelect,
  phoneSelect,
  chipMultiSelect,
  whatsappMultiSelect,
  integer,
  decimal,
  boolean,
  integerList,
  stringList,
  disks,
  videoCards,
}

class InventoryFieldSpec {
  const InventoryFieldSpec({
    required this.key,
    required this.label,
    this.kind = InventoryFieldKind.text,
    this.required = false,
    this.hint,
    this.maxLines = 1,
    this.minimum,
    this.maximum,
    this.optionType,
  });

  final String key;
  final String label;
  final InventoryFieldKind kind;
  final bool required;
  final String? hint;
  final int maxLines;
  final num? minimum;
  final num? maximum;
  final String? optionType;
}

List<InventoryFieldSpec> inventoryFieldsFor(InventoryCategory category) {
  return switch (category) {
    InventoryCategory.computers => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(
        key: 'tipo',
        label: 'Tipo',
        kind: InventoryFieldKind.select,
        required: true,
        optionType: 'TipoComputador',
      ),
      InventoryFieldSpec(
        key: 'processadorId',
        label: 'Processador',
        kind: InventoryFieldKind.processorSelect,
      ),
      InventoryFieldSpec(
        key: 'geracaoRAM',
        label: 'Geração da RAM',
        kind: InventoryFieldKind.select,
        optionType: 'GeracaoRAM',
      ),
      InventoryFieldSpec(
        key: 'memoriaRAM',
        label: 'Módulos de RAM (GB)',
        kind: InventoryFieldKind.integerList,
        hint: 'Ex.: 8, 8',
      ),
      InventoryFieldSpec(
        key: 'velocidadeRAM',
        label: 'Velocidade da RAM (MHz)',
        kind: InventoryFieldKind.integer,
        minimum: 0,
      ),
      InventoryFieldSpec(
        key: 'discos',
        label: 'Discos',
        kind: InventoryFieldKind.disks,
        hint: 'Ex.: SSD:512; HDD:1000',
        maxLines: 2,
      ),
      InventoryFieldSpec(
        key: 'placasVideo',
        label: 'Placas de vídeo',
        kind: InventoryFieldKind.videoCards,
        hint: 'Ex.: RTX 3060:12',
        maxLines: 2,
      ),
      InventoryFieldSpec(
        key: 'conectoresVideo',
        label: 'Conectores de vídeo',
        kind: InventoryFieldKind.stringList,
        hint: 'Ex.: HDMI, DisplayPort',
      ),
      InventoryFieldSpec(
        key: 'sistemaOperacional',
        label: 'Sistema operacional',
        kind: InventoryFieldKind.select,
        optionType: 'SistemaOperacional',
      ),
      InventoryFieldSpec(
        key: 'ativacaoSO',
        label: 'Ativação do sistema',
        kind: InventoryFieldKind.select,
        optionType: 'AtivacaoSO',
      ),
      InventoryFieldSpec(
        key: 'office',
        label: 'Office',
        kind: InventoryFieldKind.select,
        optionType: 'TipoOffice',
      ),
      InventoryFieldSpec(
        key: 'ativacaoOffice',
        label: 'Ativação do Office',
        kind: InventoryFieldKind.select,
        optionType: 'AtivacaoOffice',
      ),
      InventoryFieldSpec(key: 'ip', label: 'Endereço IP'),
    ],
    InventoryCategory.monitors => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(
        key: 'tamanho',
        label: 'Tamanho (polegadas)',
        kind: InventoryFieldKind.decimal,
        minimum: 0,
        maximum: 100,
      ),
      InventoryFieldSpec(
        key: 'resolucao',
        label: 'Resolução',
        kind: InventoryFieldKind.select,
        optionType: 'Resolucao',
      ),
      InventoryFieldSpec(
        key: 'frequencia',
        label: 'Frequência (Hz)',
        kind: InventoryFieldKind.integer,
        minimum: 0,
      ),
      InventoryFieldSpec(
        key: 'hdmi',
        label: 'HDMI',
        kind: InventoryFieldKind.boolean,
      ),
      InventoryFieldSpec(
        key: 'displayPort',
        label: 'DisplayPort',
        kind: InventoryFieldKind.boolean,
      ),
      InventoryFieldSpec(
        key: 'vga',
        label: 'VGA',
        kind: InventoryFieldKind.boolean,
      ),
      InventoryFieldSpec(
        key: 'dvi',
        label: 'DVI',
        kind: InventoryFieldKind.boolean,
      ),
    ],
    InventoryCategory.phones => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(
        key: 'memoriaRAM',
        label: 'Memória RAM (GB)',
        kind: InventoryFieldKind.integer,
        minimum: 0,
      ),
      InventoryFieldSpec(
        key: 'armazenamento',
        label: 'Armazenamento (GB)',
        kind: InventoryFieldKind.integer,
        minimum: 0,
      ),
      InventoryFieldSpec(
        key: 'conectividade',
        label: 'Conector carregador',
        kind: InventoryFieldKind.select,
        optionType: 'TipoConectorCarregador',
      ),
      InventoryFieldSpec(
        key: 'chipIds',
        label: 'Chips',
        kind: InventoryFieldKind.chipMultiSelect,
      ),
      InventoryFieldSpec(
        key: 'contasWhatsapp',
        label: 'Contas WhatsApp',
        kind: InventoryFieldKind.whatsappMultiSelect,
      ),
    ],
    InventoryCategory.simCards => const [
      InventoryFieldSpec(
        key: 'operadora',
        label: 'Operadora',
        kind: InventoryFieldKind.select,
        required: true,
        optionType: 'Operadora',
      ),
      InventoryFieldSpec(
        key: 'numero',
        label: 'Número',
        required: true,
        hint: '(11) 99999-9999',
      ),
      InventoryFieldSpec(key: 'dono', label: 'Titular'),
      InventoryFieldSpec(
        key: 'plano',
        label: 'Valor do plano',
        kind: InventoryFieldKind.decimal,
        minimum: 0,
      ),
      InventoryFieldSpec(
        key: 'celularId',
        label: 'Celular vinculado',
        kind: InventoryFieldKind.phoneSelect,
      ),
    ],
    InventoryCategory.mice => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(
        key: 'tipo',
        label: 'Tipo',
        kind: InventoryFieldKind.select,
        optionType: 'TipoPeriferico',
      ),
      InventoryFieldSpec(
        key: 'conectividade',
        label: 'Conectividade',
        kind: InventoryFieldKind.select,
        optionType: 'Conectividade',
      ),
    ],
    InventoryCategory.keyboards => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(
        key: 'tipo',
        label: 'Tipo',
        kind: InventoryFieldKind.select,
        optionType: 'TipoPeriferico',
      ),
      InventoryFieldSpec(
        key: 'conectividade',
        label: 'Conectividade',
        kind: InventoryFieldKind.select,
        optionType: 'Conectividade',
      ),
      InventoryFieldSpec(
        key: 'tamanho',
        label: 'Tamanho (%)',
        kind: InventoryFieldKind.integer,
        minimum: 0,
        maximum: 100,
      ),
      InventoryFieldSpec(
        key: 'switch',
        label: 'Switch',
        kind: InventoryFieldKind.select,
        optionType: 'Switch',
      ),
    ],
    InventoryCategory.headsets => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(
        key: 'tipo',
        label: 'Tipo',
        kind: InventoryFieldKind.select,
        optionType: 'TipoPeriferico',
      ),
      InventoryFieldSpec(
        key: 'microfone',
        label: 'Possui microfone',
        kind: InventoryFieldKind.boolean,
      ),
      InventoryFieldSpec(
        key: 'conectividade',
        label: 'Conectividade',
        kind: InventoryFieldKind.select,
        optionType: 'Conectividade',
      ),
    ],
    InventoryCategory.extensions => const [
      InventoryFieldSpec(key: 'modelo', label: 'Modelo', required: true),
      InventoryFieldSpec(key: 'cor', label: 'Cor'),
      InventoryFieldSpec(key: 'tipo', label: 'Tipo'),
      InventoryFieldSpec(
        key: 'configurado',
        label: 'Configurado',
        kind: InventoryFieldKind.boolean,
      ),
      InventoryFieldSpec(key: 'linha', label: 'Linha'),
      InventoryFieldSpec(key: 'numero', label: 'Número'),
      InventoryFieldSpec(key: 'ip', label: 'Endereço IP'),
      InventoryFieldSpec(key: 'mac', label: 'Endereço MAC'),
    ],
    InventoryCategory.extras => const [
      InventoryFieldSpec(key: 'categoria', label: 'Categoria', required: true),
      InventoryFieldSpec(key: 'descricao', label: 'Descrição', maxLines: 3),
      InventoryFieldSpec(
        key: 'quantidade',
        label: 'Quantidade',
        kind: InventoryFieldKind.integer,
        minimum: 0,
      ),
    ],
  };
}

abstract final class InventoryPayloadBuilder {
  static Map<String, dynamic> build({
    required InventoryCategory category,
    required String owner,
    required DateTime acquisitionDate,
    required String acquisitionPrice,
    required bool active,
    required String department,
    required String status,
    required String observations,
    required Map<String, String> inputs,
    required Map<String, bool> toggles,
    Map<String, dynamic>? existingRaw,
  }) {
    final payload = writablePayload(category, existingRaw);
    payload
      ..['usuario'] = owner.trim()
      ..['dataAquisicao'] = DateTime.utc(
        acquisitionDate.year,
        acquisitionDate.month,
        acquisitionDate.day,
      ).toIso8601String()
      ..['precoAquisicao'] = _parseDecimal(
        acquisitionPrice,
        'Preço de aquisição',
      )
      ..['ativo'] = active
      ..['setor'] = department.trim()
      ..['status'] = status.trim()
      ..['observacoes'] = _nullableText(observations);

    for (final field in inventoryFieldsFor(category)) {
      if (field.kind == InventoryFieldKind.boolean) {
        if (toggles.containsKey(field.key)) {
          payload[field.key] = toggles[field.key] ?? false;
        }
        continue;
      }
      if (!inputs.containsKey(field.key)) continue;

      final input = inputs[field.key] ?? '';
      payload[field.key] = switch (field.kind) {
        InventoryFieldKind.text =>
          field.required ? input.trim() : _nullableText(input),
        InventoryFieldKind.select ||
        InventoryFieldKind.processorSelect ||
        InventoryFieldKind.phoneSelect => _nullableText(input),
        InventoryFieldKind.chipMultiSelect ||
        InventoryFieldKind.whatsappMultiSelect => _parseStringList(input),
        InventoryFieldKind.integer => _parseInteger(input, field.label),
        InventoryFieldKind.decimal => _parseDecimal(input, field.label),
        InventoryFieldKind.boolean => false,
        InventoryFieldKind.integerList => _parseIntegerList(input, field.label),
        InventoryFieldKind.stringList => _parseStringList(input),
        InventoryFieldKind.disks => _parsePairs(
          input,
          valueKey: 'tamanho',
          label: field.label,
        ),
        InventoryFieldKind.videoCards => _parsePairs(
          input,
          valueKey: 'vram',
          label: field.label,
        ),
      };
    }

    if (category == InventoryCategory.computers) {
      final memories = (payload['memoriaRAM'] as List?) ?? const [];
      final disks = (payload['discos'] as List?) ?? const [];
      final videoCards = (payload['placasVideo'] as List?) ?? const [];
      final connectors = (payload['conectoresVideo'] as List?) ?? const [];
      payload
        ..['quantidadeSlots'] = memories.length
        ..['memoriaRAMTotal'] = memories.whereType<int>().fold(
          0,
          (sum, value) => sum + value,
        )
        ..['quantidadeDiscos'] = disks.length
        ..['quantidadePlacasVideo'] = videoCards.length
        ..['quantidadeConectoresVideo'] = connectors.length;
    }

    payload.remove('id');
    payload.remove('codigo');
    payload.remove('processador');
    payload.remove('chips');
    return payload;
  }

  static Map<String, dynamic> writablePayload(
    InventoryCategory category,
    Map<String, dynamic>? raw,
  ) {
    final source = raw ?? const <String, dynamic>{};
    final payload = <String, dynamic>{
      'usuario': source['usuario']?.toString() ?? '',
      'dataAquisicao':
          source['dataAquisicao']?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
      'precoAquisicao': _asNum(source['precoAquisicao']),
      'ativo': source['ativo'] != false,
      'setor': source['setor']?.toString() ?? '',
      'status': source['status']?.toString() ?? 'EmEstoque',
      'observacoes': source['observacoes']?.toString(),
    };

    switch (category) {
      case InventoryCategory.computers:
        final processor = source['processador'];
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'tipo': source['tipo']?.toString(),
          'processadorId':
              source['processadorId']?.toString() ??
              (processor is Map ? processor['id']?.toString() : null),
          'geracaoRAM': source['geracaoRAM']?.toString(),
          'quantidadeSlots': _asInt(source['quantidadeSlots']),
          'memoriaRAM': _integerList(source['memoriaRAM']),
          'memoriaRAMTotal': _asInt(source['memoriaRAMTotal']),
          'velocidadeRAM': _asInt(source['velocidadeRAM']),
          'quantidadeDiscos': _asInt(source['quantidadeDiscos']),
          'discos': _objectList(source['discos'], valueKey: 'tamanho'),
          'quantidadePlacasVideo': _asInt(source['quantidadePlacasVideo']),
          'placasVideo': _objectList(source['placasVideo'], valueKey: 'vram'),
          'quantidadeConectoresVideo': _asInt(
            source['quantidadeConectoresVideo'],
          ),
          'conectoresVideo': _stringList(source['conectoresVideo']),
          'sistemaOperacional': source['sistemaOperacional']?.toString(),
          'ativacaoSO': source['ativacaoSO']?.toString(),
          'office': source['office']?.toString(),
          'ativacaoOffice': source['ativacaoOffice']?.toString(),
          'ip': source['ip']?.toString(),
        });
      case InventoryCategory.monitors:
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'tamanho': _asNum(source['tamanho']),
          'resolucao': source['resolucao']?.toString(),
          'frequencia': _asInt(source['frequencia']),
          'hdmi': source['hdmi'] == true,
          'displayPort': source['displayPort'] == true,
          'vga': source['vga'] == true,
          'dvi': source['dvi'] == true,
        });
      case InventoryCategory.phones:
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'memoriaRAM': _asInt(source['memoriaRAM']),
          'armazenamento': _asInt(source['armazenamento']),
          'conectividade': source['conectividade']?.toString(),
          'chipIds': _relationIds(source['chipIds'] ?? source['chips']),
          'contasWhatsapp': _relationIds(source['contasWhatsapp']),
        });
      case InventoryCategory.simCards:
        payload.addAll({
          'operadora': source['operadora']?.toString() ?? '',
          'numero': source['numero']?.toString() ?? '',
          'dono': source['dono']?.toString(),
          'plano': _asNum(source['plano']),
          'celularId': source['celularId']?.toString(),
        });
      case InventoryCategory.mice:
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'tipo': source['tipo']?.toString(),
          'conectividade': source['conectividade']?.toString(),
        });
      case InventoryCategory.keyboards:
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'tipo': source['tipo']?.toString(),
          'conectividade': source['conectividade']?.toString(),
          'tamanho': _asInt(source['tamanho']),
          'switch': source['switch']?.toString(),
        });
      case InventoryCategory.headsets:
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'tipo': source['tipo']?.toString(),
          'microfone': source['microfone'] == true,
          'conectividade': source['conectividade']?.toString(),
        });
      case InventoryCategory.extensions:
        payload.addAll({
          'modelo': source['modelo']?.toString() ?? '',
          'cor': source['cor']?.toString(),
          'tipo': source['tipo']?.toString(),
          'configurado': source['configurado'] == true,
          'linha': source['linha']?.toString(),
          'numero': source['numero']?.toString(),
          'ip': source['ip']?.toString(),
          'mac': source['mac']?.toString(),
        });
      case InventoryCategory.extras:
        payload.addAll({
          'categoria': source['categoria']?.toString() ?? '',
          'descricao': source['descricao']?.toString(),
          'quantidade': _asInt(source['quantidade']),
        });
    }
    return payload;
  }

  static String initialText(
    Map<String, dynamic> payload,
    InventoryFieldSpec field,
  ) {
    final value = payload[field.key];
    if (value == null) return '';
    return switch (field.kind) {
      InventoryFieldKind.integerList || InventoryFieldKind.stringList =>
        value is Iterable ? value.join(', ') : '',
      InventoryFieldKind.disks => _formatPairs(value, valueKey: 'tamanho'),
      InventoryFieldKind.videoCards => _formatPairs(value, valueKey: 'vram'),
      InventoryFieldKind.boolean => '',
      InventoryFieldKind.chipMultiSelect ||
      InventoryFieldKind.whatsappMultiSelect =>
        value is Iterable ? value.join(', ') : '',
      _ => value.toString(),
    };
  }

  static String? validateField(
    InventoryCategory category,
    InventoryFieldSpec field,
    String value,
  ) {
    final trimmed = value.trim();
    if (field.required && trimmed.isEmpty) {
      return 'Informe ${field.label.toLowerCase()}.';
    }
    if (trimmed.isEmpty &&
        (field.kind == InventoryFieldKind.text ||
            field.kind == InventoryFieldKind.select ||
            field.kind == InventoryFieldKind.processorSelect ||
            field.kind == InventoryFieldKind.phoneSelect ||
            field.kind == InventoryFieldKind.chipMultiSelect ||
            field.kind == InventoryFieldKind.whatsappMultiSelect)) {
      return null;
    }

    try {
      final parsed = switch (field.kind) {
        InventoryFieldKind.integer => _parseInteger(trimmed, field.label),
        InventoryFieldKind.decimal => _parseDecimal(trimmed, field.label),
        InventoryFieldKind.integerList => _parseIntegerList(
          trimmed,
          field.label,
        ),
        InventoryFieldKind.stringList => _parseStringList(trimmed),
        InventoryFieldKind.disks => _parsePairs(
          trimmed,
          valueKey: 'tamanho',
          label: field.label,
        ),
        InventoryFieldKind.videoCards => _parsePairs(
          trimmed,
          valueKey: 'vram',
          label: field.label,
        ),
        _ => null,
      };

      if (parsed is num) {
        if (field.minimum != null && parsed < field.minimum!) {
          return '${field.label} deve ser no mínimo ${field.minimum}.';
        }
        if (field.maximum != null && parsed > field.maximum!) {
          return '${field.label} deve ser no máximo ${field.maximum}.';
        }
      }
      if (category == InventoryCategory.computers && parsed is List) {
        final limit = switch (field.key) {
          'memoriaRAM' => 16,
          'discos' => 20,
          'placasVideo' => 5,
          'conectoresVideo' => 15,
          _ => null,
        };
        if (limit != null && parsed.length > limit) {
          return '${field.label} aceita no máximo $limit itens.';
        }
      }
    } on FormatException catch (error) {
      return error.message;
    }

    if (category == InventoryCategory.simCards && field.key == 'numero') {
      final internationalDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      final international =
          trimmed.startsWith('+') &&
          RegExp(r'^\+[0-9 ()-]+$').hasMatch(trimmed) &&
          internationalDigits.length >= 10 &&
          internationalDigits.length <= 15;
      final valid =
          RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$').hasMatch(trimmed) ||
          international;
      if (!valid) {
        return 'Use (XX) XXXX-XXXX, (XX) XXXXX-XXXX ou +código internacional.';
      }
    }
    return null;
  }

  static num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _asInt(dynamic value) => _asNum(value).toInt();

  static String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double _parseDecimal(String value, String label) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return 0;
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      throw FormatException('$label deve ser um número válido.');
    }
    if (parsed < 0) throw FormatException('$label não pode ser negativo.');
    return parsed;
  }

  static int _parseInteger(String value, String label) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 0;
    final parsed = int.tryParse(normalized);
    if (parsed == null) {
      throw FormatException('$label deve ser um número inteiro.');
    }
    if (parsed < 0) throw FormatException('$label não pode ser negativo.');
    return parsed;
  }

  static List<int> _parseIntegerList(String value, String label) {
    if (value.trim().isEmpty) return [];
    return value
        .split(RegExp(r'[,;]'))
        .map((entry) => _parseInteger(entry, label))
        .toList();
  }

  static List<String> _parseStringList(String value) {
    if (value.trim().isEmpty) return [];
    return value
        .split(RegExp(r'[,;]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
  }

  static List<Map<String, dynamic>> _parsePairs(
    String value, {
    required String valueKey,
    required String label,
  }) {
    if (value.trim().isEmpty) return [];
    return value.split(';').map((entry) {
      final parts = entry.split(':');
      if (parts.length != 2 || parts.first.trim().isEmpty) {
        throw FormatException(
          '$label deve usar o formato Tipo:valor; Tipo:valor.',
        );
      }
      return <String, dynamic>{
        'tipo': parts.first.trim(),
        valueKey: _parseInteger(parts.last, label),
      };
    }).toList();
  }

  static List<int> _integerList(dynamic value) {
    if (value is! Iterable) return [];
    return value.map(_asInt).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return [];
    return value.map((entry) => entry.toString()).toList();
  }

  static List<Map<String, dynamic>> _objectList(
    dynamic value, {
    required String valueKey,
  }) {
    if (value is! Iterable) return [];
    return value.whereType<Map>().map((entry) {
      return <String, dynamic>{
        'tipo': entry['tipo']?.toString(),
        valueKey: _asInt(entry[valueKey]),
      };
    }).toList();
  }

  static List<String> _relationIds(dynamic value) {
    if (value is! Iterable) return [];
    return value
        .map(
          (entry) => entry is Map ? entry['id']?.toString() : entry?.toString(),
        )
        .whereType<String>()
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList();
  }

  static String _formatPairs(dynamic value, {required String valueKey}) {
    if (value is! Iterable) return '';
    return value
        .whereType<Map>()
        .map((entry) {
          final type = entry['tipo']?.toString() ?? '';
          final amount = _asInt(entry[valueKey]);
          return '$type:$amount';
        })
        .where((entry) => !entry.startsWith(':'))
        .join('; ');
  }
}
