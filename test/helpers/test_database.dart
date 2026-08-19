import 'package:build_access_mob_app/core/database/app_database.dart';
import 'package:drift/drift.dart';

Future<({AppDatabase db, String categoryId, String itemId})> createTestShop() async {
  final db = AppDatabase.forTesting();
  await db.batch((b) {
    b.insert(db.categories, CategoriesCompanion.insert(id: 'cat1', name: 'Test Category'));
    b.insert(db.suppliers, SuppliersCompanion.insert(id: 'sup1', name: 'Test Supplier'));
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
      ),
    );
  });
  return (db: db, categoryId: 'cat1', itemId: 'item1');
}
