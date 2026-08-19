import 'package:build_access_mob_app/core/services/order_service.dart';
import 'package:build_access_mob_app/core/services/sales_service.dart';
import 'package:build_access_mob_app/core/services/supplier_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

/// End-to-end owner flows mirroring web: restock → settle → sale, order → receive.
void main() {
  test('restock settle sale chain updates stock debt and logs', () async {
    final shop = await createTestShopContext();
    final inv = shop.services.inventory;
    final suppliers = shop.services.suppliers;
    final sales = shop.services.sales;
    final logs = shop.services.logs;

    await inv.restock(
      itemId: shop.itemId,
      quantity: 10,
      unitCost: 5,
      supplierId: shop.supplierId,
      referenceNumber: 'FLOW-RST',
    );

    await suppliers.settle(
      supplierId: shop.supplierId,
      goodsCost: 50,
      amountPaid: 20,
      context: 'stock_in',
      referenceLabel: 'FLOW-RST',
    );

    await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 5, sellingPrice: 10),
      ],
      dispatchedAt: DateTime.now(),
    );

    final item = await inv.getItem(shop.itemId);
    expect(item!.quantity, 25);

    final supplier = await suppliers.getSupplier(shop.supplierId);
    expect(supplier!.balanceOwed, 30);

    final activity = await logs.getAll();
    expect(activity.any((l) => l.action == 'STOCK_IN'), isTrue);
    expect(activity.any((l) => l.action == 'STOCK_OUT'), isTrue);
    expect(activity.any((l) => l.action == 'SUPPLIER_PAYMENT'), isTrue);

    await shop.close();
  });

  test('place order receive chain updates inventory and order status', () async {
    final shop = await createTestShopContext();
    final orders = shop.services.orders;
    final inv = shop.services.inventory;

    final placed = await orders.placeOrder(
      orderNumber: 'FLOW-ORD',
      supplierId: shop.supplierId,
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 8, unitCost: 7),
      ],
    );

    await orders.receiveOrder(
      orderId: placed.order.id,
      referenceNumber: 'FLOW-RCV',
      lines: [
        ReceiveLineInput(itemId: shop.itemId, quantity: 8, sellingPrice: 15),
      ],
    );

    final updated = await orders.getOrder(placed.order.id);
    expect(updated!.order.status, 'RECEIVED');

    final item = await inv.getItem(shop.itemId);
    expect(item!.quantity, 28);
    expect(item.sellingPrice, 15);

    await shop.close();
  });
}
