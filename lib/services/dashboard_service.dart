import '../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  const DashboardService(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> loadSummary() async {
    final response = await _apiClient.get('dashboard');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Resposta do dashboard inválida.');
    }
    return DashboardSummary.fromJson(response);
  }
}
