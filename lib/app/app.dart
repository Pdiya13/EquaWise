import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

class EquaWiseApp extends StatelessWidget {
  const EquaWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = createAppRouter();

    return MaterialApp.router(
      title: 'EquaWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}


