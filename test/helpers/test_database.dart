import 'package:build_access_mob_app/core/database/app_database.dart';
import 'package:build_access_mob_app/core/services/activity_log_service.dart';
import 'package:build_access_mob_app/core/services/financial_service.dart';
import 'package:build_access_mob_app/core/services/inventory_service.dart';
import 'package:build_access_mob_app/core/services/order_service.dart';
import 'package:build_access_mob_app/core/services/sales_service.dart';
import 'package:build_access_mob_app/core/services/supplier_service.dart';
import 'package:drift/drift.dart';

/// Pre-wired in-memory shop for service-layer tests (offline owner flows).
class TestServices {
  TestServices({
    required this.logs,
    required this.inventory,
    required this.sales,
    required this.orders,
    required this.suppliers,
    required this.financial,
  });

  final ActivityLogService logs;
  final InventoryService inventory;
  final SalesService sales;
  final OrderService orders;
  final SupplierService suppliers;
  final FinancialService financial;
}

class TestShop {
  TestShop({
    required this.db,
    required this.categoryId,
    required this.supplierId,
    required this.itemId,
    required this.item2Id,
    required this.services,
  });

  final AppDatabase db;
  final String categoryId;
  final String supplierId;
  final String itemId;
  final String item2Id;
  final TestServices services;

  Future<void> close() => db.close();
}

/// Backward-compatible helper used by existing tests.
Future<({AppDatabase db, String categoryId, String itemId})> createTestShop() async {
  final shop = await createTestShopContext();
  return (db: shop.db, categoryId: shop.categoryId, itemId: shop.itemId);
}

Future<TestShop> createTestShopContext({bool withSecondItem = true}) async {
  final db = AppDatabase.forTesting();
  const item2Id = 'item2';

  await db.batch((b) {
    b.insert(db.categories, CategoriesCompanion.insert(id: 'cat1', name: 'Test Category'));
    b.insert(
      db.suppliers,
      SuppliersCompanion.insert(
        id: 'sup1',
        name: 'Test Supplier',
        contactPerson: const Value('Jane Doe'),
        phone: const Value('0240000000'),
      ),
    );
    b.insert(
      db.items,
      ItemsCompanion.insert(
        id: 'item1',
        name: 'Test Bolt',
        categoryId: 'cat1',
        supplierId: const Value('sup1'),
        unit: const Value('pcs'),
        costPrice: const Value(5),
        sellingPrice: const Value(10),
        quantity: const Value(20),
        minThreshold: const Value(5),
      ),
    );
    if (withSecondItem) {
      b.insert(
        db.items,
        ItemsCompanion.insert(
          id: item2Id,
          name: 'Free Sample Nail',
          categoryId: 'cat1',
          supplierId: const Value('sup1'),
          unit: const Value('pcs'),
          costPrice: const Value(2),
          sellingPrice: const Value(5),
          quantity: const Value(10),
          minThreshold: const Value(3),
        ),
      );
    }
  });

  final logs = ActivityLogService(db);
  final inventory = InventoryService(db, logs);
  final sales = SalesService(db, logs);
  final orders = OrderService(db, logs);
  final suppliers = SupplierService(db, logs, orders);
  final financial = FinancialService(db, logs, inventory, sales, suppliers);

  return TestShop(
    db: db,
    categoryId: 'cat1',
    supplierId: 'sup1',
    itemId: 'item1',
    item2Id: withSecondItem ? item2Id : '',
    services: TestServices(
      logs: logs,
      inventory: inventory,
      sales: sales,
      orders: orders,
      suppliers: suppliers,
      financial: financial,
    ),
  );
}
