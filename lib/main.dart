import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_storage.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/inventory_service.dart';
import 'state/session_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig();
  late final SessionController sessionController;
  final apiClient = ApiClient(
    config: config,
    tokenProvider: () => sessionController.token,
    onUnauthorized: () => sessionController.expire(),
  );
  sessionController = SessionController(
    storage: SecureSessionStorage(),
    authService: AuthService(apiClient),
  );

  runApp(
    GestaoTiApp(
      sessionController: sessionController,
      dashboardService: DashboardService(apiClient),
      inventoryService: InventoryService(apiClient),
      config: config,
    ),
  );

  sessionController.restore();
}
