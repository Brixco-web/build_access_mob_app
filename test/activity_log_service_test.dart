import 'package:build_access_mob_app/core/database/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  test('log inserts activity row', () async {
    final shop = await createTestShopContext();
    final logs = shop.services.logs;

    await logs.log(ActionType.itemCreated, 'Created test item', quantityChange: 5);
    final all = await logs.getAll();
    expect(all.any((l) => l.details.contains('Created test item')), isTrue);

    await shop.close();
  });

  test('getAll filters by action type', () async {
    final shop = await createTestShopContext();
    final logs = shop.services.logs;

    await logs.log(ActionType.stockIn, 'Restock bolt');
    await logs.log(ActionType.stockOut, 'Sold bolt');

    final stockInOnly = await logs.getAll(actionFilter: 'STOCK_IN');
    expect(stockInOnly.every((l) => l.action == 'STOCK_IN'), isTrue);
    expect(stockInOnly.any((l) => l.details.contains('Restock')), isTrue);

    await shop.close();
  });

  test('getAll filters by search text', () async {
    final shop = await createTestShopContext();
    final logs = shop.services.logs;

    await logs.log(ActionType.orderCreated, 'Placed order ORD-XYZ');
    await logs.log(ActionType.orderCreated, 'Placed order ORD-ABC');

    final filtered = await logs.getAll(search: 'ORD-XYZ');
    expect(filtered, hasLength(1));
    expect(filtered.first.details, contains('ORD-XYZ'));

    await shop.close();
  });

  test('getAll filters by date range', () async {
    final shop = await createTestShopContext();
    final logs = shop.services.logs;

    await logs.log(ActionType.expenseCreated, 'January expense');
    final all = await logs.getAll();
    final log = all.firstWhere((l) => l.details.contains('January expense'));

    final inRange = await logs.getAll(
      from: log.createdAt.subtract(const Duration(hours: 1)),
      to: log.createdAt.add(const Duration(hours: 1)),
    );
    expect(inRange.any((l) => l.id == log.id), isTrue);

    final outOfRange = await logs.getAll(
      from: log.createdAt.add(const Duration(days: 1)),
    );
    expect(outOfRange.any((l) => l.id == log.id), isFalse);

    await shop.close();
  });
}
