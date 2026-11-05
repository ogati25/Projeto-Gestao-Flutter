import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../models/app_user.dart';
import '../services/dashboard_service.dart';
import '../services/inventory_service.dart';
import '../state/session_controller.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.sessionController,
    required this.dashboardService,
    required this.inventoryService,
    required this.config,
  });

  final AppUser user;
  final SessionController sessionController;
  final DashboardService dashboardService;
  final InventoryService inventoryService;
  final AppConfig config;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _titles = <String>['Dashboard', 'Inventário', 'Meu perfil'];

  void _selectIndex(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        service: widget.dashboardService,
        user: widget.user,
        active: _selectedIndex == 0,
      ),
      InventoryScreen(
        service: widget.inventoryService,
        defaultOwner: widget.user.fullName,
        defaultDepartment: widget.user.department,
        active: _selectedIndex == 1,
      ),
      ProfileScreen(
        user: widget.user,
        sessionController: widget.sessionController,
        config: widget.config,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 760;
        final extended = constraints.maxWidth >= 1080;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              Semantics(
                label: 'Meu perfil',
                button: true,
                onTap: () => _selectIndex(2),
                excludeSemantics: true,
                child: IconButton(
                  tooltip: 'Meu perfil',
                  onPressed: () => _selectIndex(2),
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    child: Text(
                      widget.user.initials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (desktop)
                _DesktopNavigation(
                  selectedIndex: _selectedIndex,
                  extended: extended,
                  onDestinationSelected: _selectIndex,
                  onLogout: widget.sessionController.logout,
                ),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: pages),
              ),
            ],
          ),
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectIndex,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: 'Inventário',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Perfil',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 230,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppColors.navy,
      indicatorColor: AppColors.blue,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Color(0xFFCBD5E1)),
      selectedLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: const TextStyle(color: Color(0xFFCBD5E1)),
      leading: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.hub_outlined, color: Colors.white),
            ),
            if (extended) ...[
              const SizedBox(width: 10),
              const Text(
                'NovaTech',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: extended
                ? TextButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: Color(0xFFFCA5A5)),
                    label: const Text(
                      'Sair',
                      style: TextStyle(color: Color(0xFFFCA5A5)),
                    ),
                  )
                : IconButton(
                    tooltip: 'Sair',
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: Color(0xFFFCA5A5)),
                  ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Inventário'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Meu perfil'),
        ),
      ],
    );
  }
}
