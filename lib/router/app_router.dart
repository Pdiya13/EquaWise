import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/transactions_screen.dart';
import '../ui/screens/groups_screen.dart';
import '../ui/screens/reports_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/widgets/bottom_nav.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => BottomNavShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GroupsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}


