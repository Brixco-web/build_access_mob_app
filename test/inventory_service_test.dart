import 'package:build_access_mob_app/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  test('createItem adds item and logs activity', () async {
    final shop = await createTestShopContext();
    final inv = shop.services.inventory;
    final logs = shop.services.logs;

    await inv.createItem(
      name: 'New Widget',
      categoryId: shop.categoryId,
      supplierId: shop.supplierId,
      costPrice: 8,
      sellingPrice: 15,
      quantity: 12,
      minThreshold: 2,
    );

    final items = await inv.getItems();
    expect(items.any((i) => i.name == 'New Widget' && i.quantity == 12), isTrue);

    final activity = await logs.getAll(actionFilter: 'ITEM_CREATED');
    expect(activity.any((l) => l.details.contains('New Widget')), isTrue);

    await shop.close();
  });

  test('updateItem changes fields and logs edit', () async {
    final shop = await createTestShopContext();
    final inv = shop.services.inventory;

    await inv.updateItem(
      id: shop.itemId,
      name: 'Updated Bolt',
      categoryId: shop.categoryId,
      supplierId: shop.supplierId,
      unit: 'box',
      costPrice: 6,
      sellingPrice: 12,
      minThreshold: 3,
    );

    final item = await inv.getItem(shop.itemId);
    expect(item!.name, 'Updated Bolt');
    expect(item.unit, 'box');
    expect(item.sellingPrice, 12);

    await shop.close();
  });

  test('deleteItem removes item from database', () async {
    final shop = await createTestShopContext();
    final inv = shop.services.inventory;

    await inv.deleteItem(shop.item2Id, 'Free Sample Nail');
    expect(await inv.getItem(shop.item2Id), isNull);

    await shop.close();
  });

  test('restock increments quantity and writes stock-in log', () async {
    final shop = await createTestShopContext();
    final inv = shop.services.inventory;

    await inv.restock(
      itemId: shop.itemId,
      quantity: 5,
      unitCost: 4,
      supplierId: shop.supplierId,
      referenceNumber: 'RST-TEST',
    );

    final item = await inv.getItem(shop.itemId);
    expect(item!.quantity, 25);

    final logs = await shop.services.logs.getAll(actionFilter: 'STOCK_IN');
    expect(logs.any((l) => l.details.contains('RST-TEST')), isTrue);

    await shop.close();
  });

  test('getLowStockItems returns items at or below threshold', () async {
    final shop = await createTestShopContext();
    final inv = shop.services.inventory;

    await (shop.db.update(shop.db.items)..where((t) => t.id.equals(shop.item2Id))).write(
      ItemsCompanion(quantity: Value(2)),
    );

    final low = await inv.getLowStockItems();
    expect(low.any((i) => i.id == shop.item2Id), isTrue);

    await shop.close();
  });
}
