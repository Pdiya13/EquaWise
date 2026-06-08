import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/groups_view_model.dart';
import '../../viewmodels/auth_view_model.dart';

class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  static const tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard, route: '/dashboard'),
    _TabItem(label: 'Transaction', icon: Icons.receipt_long, route: '/transactions'),
    _TabItem(label: 'Groups', icon: Icons.group, route: '/groups'),
    _TabItem(label: 'Goals', icon: Icons.flag, route: '/goals'),
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

    return Consumer2<GroupsViewModel, AuthViewModel>(
      builder: (context, groupsVm, authVm, _) {
        final userId = authVm.currentUser?.uid;
        final pending = userId == null ? 0 : groupsVm.pendingSplitsCountForUser(userId);

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              final route = tabs[index].route;
              if (route != location) context.go(route);
            },
            destinations: [
              NavigationDestination(icon: Icon(tabs[0].icon), label: tabs[0].label),
              NavigationDestination(icon: Icon(tabs[1].icon), label: tabs[1].label),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(tabs[2].icon),
                    if (pending > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            pending > 99 ? '99+' : '$pending',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: tabs[2].label,
              ),
              NavigationDestination(icon: Icon(tabs[3].icon), label: tabs[3].label),
              NavigationDestination(icon: Icon(tabs[4].icon), label: tabs[4].label),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final String route;
  const _TabItem({required this.label, required this.icon, required this.route});
}


