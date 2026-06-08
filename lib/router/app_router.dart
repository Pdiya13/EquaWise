import 'package:go_router/go_router.dart';

import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/transactions_screen.dart';
import '../ui/screens/groups_screen.dart';
import '../ui/screens/goals_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/widgets/bottom_nav.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/create_group_screen.dart';
import '../ui/screens/group_details_screen.dart';
import '../ui/screens/split_expense_screen.dart';
import '../ui/screens/pending_splits_screen.dart';
import '../ui/screens/add_personal_expense_screen.dart';
import '../ui/screens/transaction_details_screen.dart';
import '../models/transaction_model.dart';
import '../ui/screens/today_expenses_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
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
            path: '/create-group',
            name: 'create-group',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CreateGroupScreen(),
            ),
          ),
          GoRoute(
            path: '/group-details/:groupId',
            name: 'group-details',
            pageBuilder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return NoTransitionPage(
                child: GroupDetailsScreen(groupId: groupId),
              );
            },
          ),
          GoRoute(
            path: '/split-expense/:groupId',
            name: 'split-expense',
            pageBuilder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return NoTransitionPage(
                child: SplitExpenseScreen(groupId: groupId),
              );
            },
          ),
          GoRoute(
            path: '/pending-splits/:groupId',
            name: 'pending-splits',
            pageBuilder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return NoTransitionPage(
                child: PendingSplitsScreen(groupId: groupId),
              );
            },
          ),
          GoRoute(
            path: '/add-expense',
            name: 'add-expense',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AddPersonalExpenseScreen(),
            ),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GoalsScreen(),
            ),
          ),
          GoRoute(
            path: '/transaction',
            name: 'transaction',
            pageBuilder: (context, state) {
              final tx = state.extra as TransactionModel;
              return NoTransitionPage(
                child: TransactionDetailsScreen(transaction: tx),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/today-expenses',
            name: 'today-expenses',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodayExpensesScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}


