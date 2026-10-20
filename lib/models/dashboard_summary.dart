class DashboardSummary {
  const DashboardSummary({
    required this.totals,
    required this.maintenance,
    required this.distribution,
    required this.occupancy,
    required this.criticalItems,
    required this.activities,
  });

  final CategoryCounts totals;
  final CategoryCounts maintenance;
  final List<DistributionEntry> distribution;
  final List<OccupancyEntry> occupancy;
  final List<CriticalItem> criticalItems;
  final List<RecentActivity> activities;

  int get activeTotal => occupancy.fold(0, (sum, entry) => sum + entry.active);

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final maintenance = _asMap(json['manutencao'] ?? json['baixoEstoque']);
    final distributionMap = _asMap(json['distribuicao']);
    final occupancyMap = _asMap(json['ocupacao']);
    final criticalMap = _asMap(json['itensCriticos']);
    final activitiesMap = _asMap(json['atividades']);

    return DashboardSummary(
      totals: CategoryCounts.fromJson(_asMap(json['totais'])),
      maintenance: CategoryCounts.fromJson(maintenance),
      distribution: _asList(distributionMap['categorias'])
          .map(DistributionEntry.fromJson)
          .toList(),
      occupancy: _asList(occupancyMap['categorias'])
          .map(OccupancyEntry.fromJson)
          .toList(),
      criticalItems: _asList(criticalMap['itens'])
          .map(CriticalItem.fromJson)
          .toList(),
      activities: _asList(activitiesMap['atividades'])
          .map(RecentActivity.fromJson)
          .toList(),
    );
  }
}

class CategoryCounts {
  const CategoryCounts({
    required this.total,
    required this.computers,
    required this.monitors,
    required this.phones,
    required this.simCards,
    required this.mice,
    required this.keyboards,
    required this.headsets,
    required this.extensions,
    required this.extras,
  });

  final int total;
  final int computers;
  final int monitors;
  final int phones;
  final int simCards;
  final int mice;
  final int keyboards;
  final int headsets;
  final int extensions;
  final int extras;

  Map<String, int> get labeledValues => <String, int>{
    'Computadores': computers,
    'Monitores': monitors,
    'Celulares': phones,
    'Chips': simCards,
    'Mouses': mice,
    'Teclados': keyboards,
    'Fones': headsets,
    'Ramais': extensions,
    'Extras': extras,
  };

  factory CategoryCounts.fromJson(Map<String, dynamic> json) {
    return CategoryCounts(
      total: _asInt(json['total']),
      computers: _asInt(json['computadores']),
      monitors: _asInt(json['monitores']),
      phones: _asInt(json['celulares']),
      simCards: _asInt(json['chips']),
      mice: _asInt(json['mouses']),
      keyboards: _asInt(json['teclados']),
      headsets: _asInt(json['fones']),
      extensions: _asInt(json['ramais']),
      extras: _asInt(json['extras']),
    );
  }
}

class DistributionEntry {
  const DistributionEntry({
    required this.name,
    required this.quantity,
    required this.percentage,
  });

  final String name;
  final int quantity;
  final double percentage;

  factory DistributionEntry.fromJson(Map<String, dynamic> json) {
    return DistributionEntry(
      name: json['nome']?.toString() ?? 'Categoria',
      quantity: _asInt(json['quantidade']),
      percentage: _asDouble(json['percentual']),
    );
  }
}

class OccupancyEntry {
  const OccupancyEntry({
    required this.name,
    required this.active,
    required this.inactive,
    required this.total,
    required this.percentage,
  });

  final String name;
  final int active;
  final int inactive;
  final int total;
  final double percentage;

  factory OccupancyEntry.fromJson(Map<String, dynamic> json) {
    return OccupancyEntry(
      name: json['nome']?.toString() ?? 'Categoria',
      active: _asInt(json['ativos']),
      inactive: _asInt(json['inativos']),
      total: _asInt(json['total']),
      percentage: _asDouble(json['percentual']),
    );
  }
}

class CriticalItem {
  const CriticalItem({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.status,
    required this.active,
  });

  final String id;
  final String name;
  final String code;
  final String category;
  final String status;
  final bool active;

  factory CriticalItem.fromJson(Map<String, dynamic> json) {
    return CriticalItem(
      id: json['id']?.toString() ?? '',
      name: json['nome']?.toString() ?? 'Item sem nome',
      code: json['sku']?.toString() ?? '',
      category: json['categoria']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      active: json['ativo'] == true,
    );
  }
}

class RecentActivity {
  const RecentActivity({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.user,
    this.acquiredAt,
  });

  final String id;
  final String name;
  final String category;
  final DateTime? acquiredAt;
  final String status;
  final String user;

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id']?.toString() ?? '',
      name: json['nome']?.toString() ?? 'Item sem nome',
      category: json['categoria']?.toString() ?? '',
      acquiredAt: DateTime.tryParse(json['dataAquisicao']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      user: json['usuario']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! Iterable) return const <Map<String, dynamic>>[];
  return value.map(_asMap).toList();
}

int _asInt(dynamic value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  _ => int.tryParse(value?.toString() ?? '') ?? 0,
};

double _asDouble(dynamic value) => switch (value) {
  double number => number,
  num number => number.toDouble(),
  _ => double.tryParse(value?.toString() ?? '') ?? 0,
};
