import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/dashboard_service.dart';
import 'services/inventory_service.dart';
import 'state/session_controller.dart';

class GestaoTiApp extends StatelessWidget {
  const GestaoTiApp({
    super.key,
    required this.sessionController,
    required this.dashboardService,
    required this.inventoryService,
    required this.config,
  });

  final SessionController sessionController;
  final DashboardService dashboardService;
  final InventoryService inventoryService;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de TI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: sessionController,
        builder: (context, _) {
          if (sessionController.status == SessionStatus.restoring) {
            return const _SplashScreen();
          }

          final user = sessionController.user;
          if (sessionController.isSignedIn && user != null) {
            return HomeShell(
              user: user,
              sessionController: sessionController,
              dashboardService: dashboardService,
              inventoryService: inventoryService,
              config: config,
            );
          }

          return LoginScreen(sessionController: sessionController);
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Semantics(
          label: 'Carregando Gestão de TI',
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_outlined, color: Colors.white, size: 54),
              SizedBox(height: 18),
              Text(
                'NovaTech Solutions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 26),
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  color: AppColors.blueBright,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
