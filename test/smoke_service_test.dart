import 'package:build_access_mob_app/core/services/activity_log_service.dart';
import 'package:build_access_mob_app/core/services/inventory_service.dart';
import 'package:build_access_mob_app/core/services/order_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

/// Service-level smoke tests mirroring key owner flows (offline, no device required).
void main() {
  test('restock increases item quantity', () async {
    final shop = await createTestShop();
    final inventory = InventoryService(shop.db, ActivityLogService(shop.db));

    await inventory.restock(
      itemId: shop.itemId,
      quantity: 10,
      unitCost: 4,
      supplierId: 'sup1',
      referenceNumber: 'RESTOCK-001',
    );

    final item = await inventory.getItem(shop.itemId);
    expect(item!.quantity, 30);

    await shop.db.close();
  });

  test('order place and receive updates stock and selling price', () async {
    final shop = await createTestShop();
    final logs = ActivityLogService(shop.db);
    final orders = OrderService(shop.db, logs);

    final placed = await orders.placeOrder(
      orderNumber: 'ORD-001',
      supplierId: 'sup1',
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 5, unitCost: 6),
      ],
    );

    await orders.receiveOrder(
      orderId: placed.order.id,
      referenceNumber: 'RCV-001',
      lines: [
        ReceiveLineInput(itemId: shop.itemId, quantity: 5, sellingPrice: 12),
      ],
    );

    final item = await (shop.db.select(shop.db.items)..where((t) => t.id.equals(shop.itemId))).getSingle();
    expect(item.quantity, 25);
    expect(item.sellingPrice, 12);

    await shop.db.close();
  });
}
