import 'package:build_access_mob_app/core/services/activity_log_service.dart';
import 'package:build_access_mob_app/core/services/sales_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  test('recordSale decrements stock and assigns sale reference', () async {
    final shop = await createTestShop();
    final sales = SalesService(shop.db, ActivityLogService(shop.db));

    final result = await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 3, sellingPrice: 10),
      ],
      dispatchedAt: DateTime(2026, 1, 15),
      customerReference: 'John Doe',
    );

    expect(result.saleReference, isNotEmpty);
    expect(result.totalAmount, 30);
    expect(result.lines, hasLength(1));
    expect(result.lines.first.itemName, 'Test Bolt');

    final item = await (shop.db.select(shop.db.items)..where((t) => t.id.equals(shop.itemId))).getSingle();
    expect(item.quantity, 17);

    final stockOuts = await shop.db.select(shop.db.stockOuts).get();
    expect(stockOuts, hasLength(1));
    expect(stockOuts.first.saleReference, result.saleReference);
    expect(stockOuts.first.customerReference, 'John Doe');

    await shop.db.close();
  });

  test('recordSale rejects insufficient stock', () async {
    final shop = await createTestShop();
    final sales = SalesService(shop.db, ActivityLogService(shop.db));

    expect(
      () => sales.recordSale(
        lines: [
          SaleLineInput(itemId: shop.itemId, quantity: 100, sellingPrice: 10),
        ],
        dispatchedAt: DateTime.now(),
      ),
      throwsA(isA<Exception>()),
    );

    await shop.db.close();
  });
}
