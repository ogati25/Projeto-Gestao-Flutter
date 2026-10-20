import '../core/network/api_client.dart';
import '../models/inventory_item.dart';

class InventoryService {
  const InventoryService(this._apiClient);

  final ApiClient _apiClient;

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
}
