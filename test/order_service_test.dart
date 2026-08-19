import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';
import 'package:build_access_mob_app/core/services/order_service.dart';

void main() {
  test('placeOrder creates pending order with lines', () async {
    final shop = await createTestShopContext();
    final orders = shop.services.orders;

    final placed = await orders.placeOrder(
      orderNumber: 'ORD-100',
      supplierId: shop.supplierId,
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 10, unitCost: 6),
      ],
    );

    expect(placed.order.status, 'PENDING');
    expect(placed.order.totalCost, 60);
    expect(placed.items, hasLength(1));

    await shop.close();
  });

  test('partial receive sets PARTIALLY_RECEIVED', () async {
    final shop = await createTestShopContext();
    final orders = shop.services.orders;

    final placed = await orders.placeOrder(
      orderNumber: 'ORD-200',
      supplierId: shop.supplierId,
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 10, unitCost: 6),
      ],
    );

    await orders.receiveOrder(
      orderId: placed.order.id,
      referenceNumber: 'RCV-PART',
      lines: [
        ReceiveLineInput(itemId: shop.itemId, quantity: 4, sellingPrice: 12),
      ],
    );

    final updated = await orders.getOrder(placed.order.id);
    expect(updated!.order.status, 'PARTIALLY_RECEIVED');

    final item = await shop.services.inventory.getItem(shop.itemId);
    expect(item!.quantity, 24);

    await shop.close();
  });

  test('full receive sets RECEIVED and updates selling price', () async {
    final shop = await createTestShopContext();
    final orders = shop.services.orders;

    final placed = await orders.placeOrder(
      orderNumber: 'ORD-300',
      supplierId: shop.supplierId,
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 5, unitCost: 6),
      ],
    );

    await orders.receiveOrder(
      orderId: placed.order.id,
      referenceNumber: 'RCV-FULL',
      lines: [
        ReceiveLineInput(itemId: shop.itemId, quantity: 5, sellingPrice: 14),
      ],
    );

    final updated = await orders.getOrder(placed.order.id);
    expect(updated!.order.status, 'RECEIVED');

    final item = await shop.services.inventory.getItem(shop.itemId);
    expect(item!.quantity, 25);
    expect(item.sellingPrice, 14);

    await shop.close();
  });

  test('cancelOrder cancels pending order', () async {
    final shop = await createTestShopContext();
    final orders = shop.services.orders;

    final placed = await orders.placeOrder(
      orderNumber: 'ORD-400',
      supplierId: shop.supplierId,
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 3, unitCost: 6),
      ],
    );

    await orders.cancelOrder(placed.order.id, placed.order.orderNumber);
    final updated = await orders.getOrder(placed.order.id);
    expect(updated!.order.status, 'CANCELLED');

    await shop.close();
  });
}
