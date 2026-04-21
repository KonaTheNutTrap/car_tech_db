import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'vehicles_screen.dart';
import 'jobs_screen.dart';
import 'inventory_screen.dart';
import 'invoices_screen.dart';
import 'users_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.people, 'Customers'),
    _NavItem(Icons.directions_car, 'Vehicles'),
    _NavItem(Icons.build, 'Jobs'),
    _NavItem(Icons.inventory_2, 'Inventory'),
    _NavItem(Icons.receipt_long, 'Invoices'),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomersScreen(),
    VehiclesScreen(),
    JobsScreen(),
    InventoryScreen(),
    InvoicesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppTheme.primary,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) =>
                  setState(() => _selectedIndex = i),
              extended: MediaQuery.of(context).size.width >= 1100,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.car_repair,
                        color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text('Car Tech',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (auth.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.manage_accounts,
                                color: Colors.white70),
                            tooltip: 'Users',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UsersScreen()),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.white70),
                          tooltip: 'Logout',
                          onPressed: () => auth.logout(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon,
                            color: Colors.white54),
                        selectedIcon:
                            Icon(item.icon, color: Colors.white),
                        label: Text(item.label,
                            style:
                                const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              selectedIconTheme:
                  const IconThemeData(color: Colors.white),
              unselectedIconTheme:
                  const IconThemeData(color: Colors.white54),
              indicatorColor:
                  Colors.white.withOpacity(0.15),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Users',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsersScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppTheme.primary,
        indicatorColor: Colors.white.withOpacity(0.15),
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon, color: Colors.white54),
                  selectedIcon: Icon(item.icon, color: Colors.white),
                  label: item.label,
                ))
            .toList(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
