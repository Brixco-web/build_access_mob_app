import 'package:build_access_mob_app/core/database/enums.dart';
import 'package:build_access_mob_app/core/services/sales_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  test('recordSale decrements stock and assigns sale reference', () async {
    final shop = await createTestShopContext();
    final sales = shop.services.sales;

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

    final item = await shop.services.inventory.getItem(shop.itemId);
    expect(item!.quantity, 17);

    final stockOuts = await shop.db.select(shop.db.stockOuts).get();
    expect(stockOuts, hasLength(1));
    expect(stockOuts.first.saleReference, result.saleReference);
    expect(stockOuts.first.customerReference, 'John Doe');

    await shop.close();
  });

  test('recordSale rejects insufficient stock', () async {
    final shop = await createTestShopContext();
    final sales = shop.services.sales;

    expect(
      () => sales.recordSale(
        lines: [
          SaleLineInput(itemId: shop.itemId, quantity: 100, sellingPrice: 10),
        ],
        dispatchedAt: DateTime.now(),
      ),
      throwsA(isA<Exception>()),
    );

    await shop.close();
  });

  test('money discount reduces total amount', () async {
    final shop = await createTestShopContext();
    final sales = shop.services.sales;

    final result = await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 2, sellingPrice: 10),
      ],
      dispatchedAt: DateTime(2026, 2, 1),
      discount: const DiscountInput(type: DiscountType.money, moneyAmount: 5),
    );

    expect(result.totalAmount, 15);

    await shop.close();
  });

  test('free item discount decrements free stock', () async {
    final shop = await createTestShopContext();
    final sales = shop.services.sales;

    await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 1, sellingPrice: 10),
      ],
      dispatchedAt: DateTime(2026, 2, 2),
      discount: DiscountInput(
        type: DiscountType.freeItem,
        freeItemId: shop.item2Id,
        freeQuantity: 2,
      ),
    );

    final freeItem = await shop.services.inventory.getItem(shop.item2Id);
    expect(freeItem!.quantity, 8);

    final byRef = await sales.getSalesByReference(
      (await shop.db.select(shop.db.stockOuts).get()).first.saleReference!,
    );
    expect(byRef.length, greaterThanOrEqualTo(2));

    await shop.close();
  });

  test('deleteSale restores stock quantity', () async {
    final shop = await createTestShopContext();
    final sales = shop.services.sales;

    final result = await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 4, sellingPrice: 10),
      ],
      dispatchedAt: DateTime(2026, 2, 3),
    );

    await sales.deleteSale(result.stockOutIds.first);
    final item = await shop.services.inventory.getItem(shop.itemId);
    expect(item!.quantity, 20);

    await shop.close();
  });

  test('getSalesByReference groups multi-line sale', () async {
    final shop = await createTestShopContext();
    final sales = shop.services.sales;

    final result = await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 1, sellingPrice: 10),
        SaleLineInput(itemId: shop.item2Id, quantity: 2, sellingPrice: 5),
      ],
      dispatchedAt: DateTime(2026, 2, 4),
    );

    final grouped = await sales.getSalesByReference(result.saleReference);
    expect(grouped, hasLength(2));
    expect(grouped.every((s) => s.saleReference == result.saleReference), isTrue);

    await shop.close();
  });
}
