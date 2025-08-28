import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  static const tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard, route: '/dashboard'),
    _TabItem(label: 'Transactions', icon: Icons.receipt_long, route: '/transactions'),
    _TabItem(label: 'Groups', icon: Icons.group, route: '/groups'),
    _TabItem(label: 'Reports', icon: Icons.pie_chart, route: '/reports'),
    _TabItem(label: 'Profile', icon: Icons.person, route: '/profile'),
  ];

  int _indexForLocation(String location) {
    final idx = tabs.indexWhere((t) => location.startsWith(t.route));
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          final route = tabs[index].route;
          if (route != location) context.go(route);
        },
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final String route;
  const _TabItem({required this.label, required this.icon, required this.route});
}


