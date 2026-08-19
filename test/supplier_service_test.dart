import 'package:build_access_mob_app/core/services/order_service.dart';
import 'package:build_access_mob_app/core/services/supplier_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';

void main() {
  test('createSupplier adds supplier and logs activity', () async {
    final shop = await createTestShopContext();
    final suppliers = shop.services.suppliers;

    await suppliers.createSupplier(name: 'New Wholesaler', phone: '0551111111');
    final list = await suppliers.getSuppliers();
    expect(list.any((s) => s.name == 'New Wholesaler'), isTrue);

    final logs = await shop.services.logs.getAll(actionFilter: 'SUPPLIER_CREATED');
    expect(logs, isNotEmpty);

    await shop.close();
  });

  test('settle with partial payment increases balanceOwed', () async {
    final shop = await createTestShopContext();
    final suppliers = shop.services.suppliers;

    await suppliers.settle(
      supplierId: shop.supplierId,
      goodsCost: 100,
      amountPaid: 40,
      expenses: [ExpenseLineInput(label: 'Carriage', amount: 10)],
      context: 'stock_in',
      referenceLabel: 'RST-001',
    );

    final supplier = await suppliers.getSupplier(shop.supplierId);
    expect(supplier!.balanceOwed, 70);

    await shop.close();
  });

  test('payDebt reduces balanceOwed', () async {
    final shop = await createTestShopContext();
    final suppliers = shop.services.suppliers;

    await suppliers.settle(
      supplierId: shop.supplierId,
      goodsCost: 50,
      amountPaid: 0,
      context: 'order',
      referenceLabel: 'ORD-001',
    );

    await suppliers.payDebt(supplierId: shop.supplierId, amount: 20);
    final supplier = await suppliers.getSupplier(shop.supplierId);
    expect(supplier!.balanceOwed, 30);

    await shop.close();
  });

  test('getSuppliersWithDebt includes balance and pending order debt', () async {
    final shop = await createTestShopContext();
    final suppliers = shop.services.suppliers;
    final orders = shop.services.orders;

    await suppliers.settle(
      supplierId: shop.supplierId,
      goodsCost: 25,
      amountPaid: 0,
      context: 'stock_in',
      referenceLabel: 'RST-002',
    );

    await orders.placeOrder(
      orderNumber: 'ORD-DEBT',
      supplierId: shop.supplierId,
      lines: [
        OrderLineInput(itemId: shop.itemId, quantity: 4, unitCost: 10),
      ],
    );

    final debtRows = await suppliers.getSuppliersWithDebt();
    expect(debtRows.any((r) => r.id == shop.supplierId && r.amountOwed > 25), isTrue);

    await shop.close();
  });

  test('updateSupplier and deleteSupplier work', () async {
    final shop = await createTestShopContext();
    final suppliers = shop.services.suppliers;

    await suppliers.createSupplier(name: 'Temp Supplier');
    final created = (await suppliers.getSuppliers()).firstWhere((s) => s.name == 'Temp Supplier');

    await suppliers.updateSupplier(
      id: created.id,
      name: 'Renamed Supplier',
      phone: '999',
    );
    final updated = await suppliers.getSupplier(created.id);
    expect(updated!.name, 'Renamed Supplier');

    await suppliers.deleteSupplier(created.id, updated.name);
    expect(await suppliers.getSupplier(created.id), isNull);

    await shop.close();
  });
}
