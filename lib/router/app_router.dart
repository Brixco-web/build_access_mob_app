import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/auth_provider.dart';
import '../features/auth/lock_screen.dart';
import '../features/activity_logs/activity_logs_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/suppliers/suppliers_screen.dart';
import '../shell/owner_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onLock = state.matchedLocation == '/lock';
      if (!auth.isUnlocked && !onLock) return '/lock';
      if (auth.isUnlocked && onLock) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/lock',
        builder: (_, state) => LockScreen(setupMode: state.uri.queryParameters['setup'] == '1'),
      ),
      ShellRoute(
        builder: (context, state, child) => OwnerShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
          GoRoute(path: '/financial', builder: (_, __) => const FinancialScreen()),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/activity-logs', builder: (_, __) => const ActivityLogsScreen()),
          GoRoute(path: '/suppliers', builder: (_, __) => const SuppliersScreen()),
          GoRoute(
            path: '/suppliers/:id',
            builder: (_, state) => SupplierDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
