import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../services/activity_log_service.dart';
import '../services/financial_service.dart';
import '../services/inventory_service.dart';
import '../services/order_service.dart';
import '../services/sales_service.dart';
import '../services/supplier_service.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService(ref.watch(databaseProvider));
});

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(ref.watch(databaseProvider), ref.watch(activityLogServiceProvider));
});

final salesServiceProvider = Provider<SalesService>((ref) {
  return SalesService(ref.watch(databaseProvider), ref.watch(activityLogServiceProvider));
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(databaseProvider), ref.watch(activityLogServiceProvider));
});

final supplierServiceProvider = Provider<SupplierService>((ref) {
  return SupplierService(
    ref.watch(databaseProvider),
    ref.watch(activityLogServiceProvider),
    ref.watch(orderServiceProvider),
  );
});

final financialServiceProvider = Provider<FinancialService>((ref) {
  return FinancialService(
    ref.watch(databaseProvider),
    ref.watch(activityLogServiceProvider),
    ref.watch(inventoryServiceProvider),
    ref.watch(salesServiceProvider),
    ref.watch(supplierServiceProvider),
  );
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(inventoryServiceProvider).getCategories();
});

final itemsStreamProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(inventoryServiceProvider).watchItems();
});

final salesStreamProvider = StreamProvider<List<StockOut>>((ref) {
  return ref.watch(salesServiceProvider).watchSales();
});

final dashboardProvider = FutureProvider((ref) async {
  return ref.watch(financialServiceProvider).getDashboard();
});

final ordersProvider = FutureProvider((ref) async {
  return ref.watch(orderServiceProvider).getOrders();
});

final suppliersProvider = FutureProvider((ref) async {
  return ref.watch(supplierServiceProvider).getSuppliers();
});
