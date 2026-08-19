import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activity_logs/activity_logs_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/financial/financial_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/orders/orders_screen.dart';
import '../features/sales/sales_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/suppliers/suppliers_screen.dart';
import '../shell/owner_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (state.matchedLocation == '/reports') return '/financial';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => OwnerShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen()),
          GoRoute(path: '/sales', builder: (_, _) => const SalesScreen()),
          GoRoute(path: '/financial', builder: (_, _) => const FinancialScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/activity-logs', builder: (_, _) => const ActivityLogsScreen()),
          GoRoute(path: '/suppliers', builder: (_, _) => const SuppliersScreen()),
          GoRoute(
            path: '/suppliers/:id',
            builder: (_, state) => SupplierDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
