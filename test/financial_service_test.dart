import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_database.dart';
import 'package:build_access_mob_app/core/services/sales_service.dart';

void main() {
  test('addExpense and deleteExpense update other expenses', () async {
    final shop = await createTestShopContext();
    final financial = shop.services.financial;

    await financial.addExpense(label: 'Rent', amount: 200, notes: 'Shop rent');
    var expenses = await shop.db.select(shop.db.otherExpenses).get();
    expect(expenses.any((e) => e.label == 'Rent' && e.amount == 200), isTrue);

    final expense = expenses.firstWhere((e) => e.label == 'Rent');
    await financial.deleteExpense(expense.id, expense.label);
    expenses = await shop.db.select(shop.db.otherExpenses).get();
    expect(expenses.any((e) => e.id == expense.id), isFalse);

    await shop.close();
  });

  test('getSummary includes revenue after sale in month', () async {
    final shop = await createTestShopContext();
    final financial = shop.services.financial;
    final sales = shop.services.sales;

    final now = DateTime.now();
    await sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 2, sellingPrice: 10),
      ],
      dispatchedAt: now,
    );

    final summary = await financial.getSummary(now.year, now.month);
    expect(summary.totalRevenue, greaterThanOrEqualTo(20));
    expect(summary.totalCommission, greaterThan(0));

    await shop.close();
  });

  test('getDashboard returns item and supplier counts', () async {
    final shop = await createTestShopContext();
    final dashboard = await shop.services.financial.getDashboard();

    expect(dashboard.totalItems, 2);
    expect(dashboard.totalSuppliers, 1);
    expect(dashboard.totalStockValue, greaterThan(0));

    await shop.close();
  });

  test('getMonthlyReport includes sold item breakdown', () async {
    final shop = await createTestShopContext();
    final now = DateTime.now();

    await shop.services.sales.recordSale(
      lines: [
        SaleLineInput(itemId: shop.itemId, quantity: 1, sellingPrice: 10),
      ],
      dispatchedAt: now,
    );

    final report = await shop.services.financial.getMonthlyReport(now.year, now.month);
    expect(report.totalSalesQty, greaterThanOrEqualTo(1));
    expect(report.breakdown.any((r) => r.itemName == 'Test Bolt'), isTrue);

    await shop.close();
  });
}
