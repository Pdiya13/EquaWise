import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../router/app_router.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/groups_view_model.dart';
import '../viewmodels/transactions_view_model.dart';
import '../viewmodels/budgets_view_model.dart';

class EquaWiseApp extends StatelessWidget {
  const EquaWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = createAppRouter();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => GroupsViewModel()),
        ChangeNotifierProvider(create: (_) => TransactionsViewModel()),
        ChangeNotifierProvider(create: (_) => BudgetsViewModel()),
      ],
      child: MaterialApp.router(
        title: 'EquaWise',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB3E5FC)),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}


