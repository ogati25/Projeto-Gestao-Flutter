import '../core/network/api_client.dart';
import '../models/inventory_item.dart';

class InventoryService {
  const InventoryService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, List<String>>> loadOptions() async {
    final response = await _apiClient.get('opcoes');
    if (response is! Map) {
      throw const FormatException('Resposta de opções inválida.');
    }

    return response.map<String, List<String>>((key, value) {
      final values = value is Iterable
          ? value
                .map((entry) => entry.toString().trim())
                .where((entry) => entry.isNotEmpty)
                .toSet()
                .toList()
          : <String>[];
      return MapEntry(key.toString().toLowerCase(), values);
    });
  }

  Future<List<InventoryLookupItem>> listProcessors() async {
    final response = await _apiClient.get('processadores');
    return _lookupItems(
      response,
      labelBuilder: (entry) {
        final name = entry['nome']?.toString().trim() ?? '';
        final speed = entry['velocidade']?.toString().trim() ?? '';
        return speed.isEmpty ? name : '$name - $speed GHz';
      },
    );
  }

  Future<List<InventoryLookupItem>> listPhones() async {
    final response = await _apiClient.get('celulares');
    return _lookupItems(
      response,
      labelBuilder: (entry) {
        final code = entry['codigo']?.toString().trim() ?? '';
        final model = entry['modelo']?.toString().trim() ?? '';
        return [code, model].where((part) => part.isNotEmpty).join(' - ');
      },
    );
  }

  Future<List<InventoryLookupItem>> listChips() async {
    final response = await _apiClient.get('chips');
    return _lookupItems(
      response,
      labelBuilder: (entry) {
        final number = entry['numero']?.toString().trim() ?? '';
        final owner = entry['dono']?.toString().trim() ?? '';
        final operator = entry['operadora']?.toString().trim() ?? '';
        return [
          number,
          if (owner.isNotEmpty) owner,
          if (operator.isNotEmpty) operator,
        ].where((part) => part.isNotEmpty).join(' - ');
      },
    );
  }

  Future<List<InventoryItem>> list(InventoryCategory category) async {
    final response = await _apiClient.get(category.endpoint);
    if (response is! List) {
      throw const FormatException('Resposta do inventário inválida.');
    }

    return response
        .whereType<Map>()
        .map(
          (entry) => InventoryItem.fromJson(
            category,
            entry.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<InventoryItem> create(
    InventoryCategory category,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(category.endpoint, body: payload);
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta de criação inválida.');
    }
    return InventoryItem.fromJson(category, response);
  }

  Future<void> update(
    InventoryCategory category,
    String id,
    Map<String, dynamic> payload,
  ) async {
    if (id.isEmpty) throw const FormatException('Item sem identificador.');
    await _apiClient.put('${category.endpoint}/$id', body: payload);
  }

  Future<void> delete(InventoryCategory category, String id) async {
    if (id.isEmpty) throw const FormatException('Item sem identificador.');
    await _apiClient.delete('${category.endpoint}/$id');
  }

  static List<InventoryLookupItem> _lookupItems(
    dynamic response, {
    required String Function(Map<String, dynamic>) labelBuilder,
  }) {
    if (response is! List) {
      throw const FormatException('Resposta de relacionamento inválida.');
    }

    return response
        .whereType<Map>()
        .map((raw) {
          final entry = raw.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
          final id = entry['id']?.toString().trim() ?? '';
          final label = labelBuilder(entry).trim();
          return InventoryLookupItem(
            id: id,
            label: label.isEmpty ? id : label,
            raw: entry,
          );
        })
        .where((entry) => entry.id.isNotEmpty)
        .toList();
  }
}

class InventoryLookupItem {
  const InventoryLookupItem({
    required this.id,
    required this.label,
    required this.raw,
  });

  final String id;
  final String label;
  final Map<String, dynamic> raw;
}
