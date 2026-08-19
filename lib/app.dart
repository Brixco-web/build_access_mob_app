import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/database_provider.dart';
import '../core/theme/app_theme.dart';
import '../router/app_router.dart';

class ApexApp extends ConsumerWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(databaseInitProvider);
    final router = ref.watch(routerProvider);

    return init.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Failed to start: $e'))),
      ),
      data: (_) => MaterialApp.router(
        title: 'Apex Building Accessories',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}
