enum InventoryCategory {
  computers('computadores', 'Computadores'),
  monitors('monitores', 'Monitores'),
  phones('celulares', 'Celulares'),
  simCards('chips', 'Chips'),
  mice('mouses', 'Mouses'),
  keyboards('teclados', 'Teclados'),
  headsets('fones', 'Fones'),
  extensions('ramais', 'Ramais'),
  extras('extras', 'Extras');

  const InventoryCategory(this.endpoint, this.label);

  final String endpoint;
  final String label;
}

class InventoryItem {
  InventoryItem({required this.category, required Map<String, dynamic> raw})
    : raw = Map<String, dynamic>.unmodifiable(raw);

  final InventoryCategory category;
  final Map<String, dynamic> raw;

  String get id => raw['id']?.toString() ?? '';
  String get code => raw['codigo']?.toString() ?? '';
  String get status => raw['status']?.toString() ?? 'Não informado';
  String get owner => raw['usuario']?.toString() ?? 'Não informado';
  String get department => raw['setor']?.toString() ?? 'Não informado';
  bool get active => raw['ativo'] != false;
  DateTime? get acquiredAt =>
      DateTime.tryParse(raw['dataAquisicao']?.toString() ?? '');
  num? get acquisitionPrice => raw['precoAquisicao'] is num
      ? raw['precoAquisicao'] as num
      : num.tryParse(raw['precoAquisicao']?.toString() ?? '');

  String get title {
    final value = switch (category) {
      InventoryCategory.simCards => raw['numero'],
      InventoryCategory.extras => raw['descricao'] ?? raw['categoria'],
      _ => raw['modelo'],
    };
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
    if (code.isNotEmpty) return code;
    return category.label;
  }

  String get searchableText {
    return <String>[
      title,
      code,
      status,
      owner,
      department,
      ...raw.values.map((value) => value?.toString() ?? ''),
    ].join(' ').toLowerCase();
  }

  factory InventoryItem.fromJson(
    InventoryCategory category,
    Map<String, dynamic> json,
  ) {
    return InventoryItem(category: category, raw: json);
  }
}
