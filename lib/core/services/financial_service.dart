import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'activity_log_service.dart';
import 'inventory_service.dart';
import 'sales_service.dart';
import 'supplier_service.dart';

const _uuid = Uuid();

class FinancialSummary {
  FinancialSummary({
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalStockReceived,
    required this.totalOtherExpenses,
    required this.inventoryValue,
    required this.pendingOrderValue,
    required this.pendingOrderCount,
    required this.grossMarginPct,
    required this.netCashFlow,
    required this.totalOutstandingDebt,
    required this.suppliersWithDebt,
    required this.otherExpenses,
  });

  final double totalRevenue;
  final double totalCommission;
  final double totalStockReceived;
  final double totalOtherExpenses;
  final double inventoryValue;
  final double pendingOrderValue;
  final int pendingOrderCount;
  final double grossMarginPct;
  final double netCashFlow;
  final double totalOutstandingDebt;
  final List<SupplierDebtRow> suppliersWithDebt;
  final List<OtherExpense> otherExpenses;
}

class ReportBreakdownRow {
  ReportBreakdownRow({
    required this.itemName,
    required this.unit,
    required this.stockInQty,
    required this.stockInValue,
    required this.soldQty,
    required this.salesValue,
  });

  final String itemName;
  final String unit;
  final int stockInQty;
  final double stockInValue;
  final int soldQty;
  final double salesValue;
}

class MonthlyReport {
  MonthlyReport({
    required this.totalStockReceivedQty,
    required this.totalStockReceivedValue,
    required this.totalSalesQty,
    required this.totalSalesValue,
    required this.netInventoryChange,
    required this.breakdown,
  });

  final int totalStockReceivedQty;
  final double totalStockReceivedValue;
  final int totalSalesQty;
  final double totalSalesValue;
  final double netInventoryChange;
  final List<ReportBreakdownRow> breakdown;
}

class DashboardData {
  DashboardData({
    required this.totalItems,
    required this.totalStockValue,
    required this.totalSuppliers,
    required this.currentMonthStockIn,
    required this.previousMonthStockIn,
    required this.currentMonthSales,
    required this.previousMonthSales,
    required this.lowStockItems,
    required this.recentStockIns,
  });

  final int totalItems;
  final double totalStockValue;
  final int totalSuppliers;
  final double currentMonthStockIn;
  final double previousMonthStockIn;
  final double currentMonthSales;
  final double previousMonthSales;
  final List<Item> lowStockItems;
  final List<RecentStockInRow> recentStockIns;
}

class RecentStockInRow {
  RecentStockInRow({
    required this.id,
    required this.referenceNumber,
    required this.supplierName,
    required this.receivedDate,
    required this.totalCost,
    required this.itemCount,
  });

  final String id;
  final String referenceNumber;
  final String supplierName;
  final DateTime receivedDate;
  final double totalCost;
  final int itemCount;
}

class FinancialService {
  FinancialService(
    this._db,
    this._logs,
    this._inventory,
    this._sales,
    this._suppliers,
  );

  final AppDatabase _db;
  final ActivityLogService _logs;
  final InventoryService _inventory;
  final SalesService _sales;
  final SupplierService _suppliers;

  (DateTime, DateTime) _monthRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return (start, end);
  }

  bool _inRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && date.isBefore(end);
  }

  Future<FinancialSummary> getSummary(int year, int month) async {
    final (start, end) = _monthRange(year, month);

    final allStockIns = await _db.select(_db.stockIns).get();
    final stockIns = allStockIns.where((s) => _inRange(s.receivedDate, start, end)).toList();

    final totalStockReceived = stockIns.fold(0.0, (s, r) => s + r.totalCost);
    final totalRevenue = await _sales.getTotalRevenue(from: start, to: end.subtract(const Duration(microseconds: 1)));
    final totalCommission = await _sales.getTotalProfit(from: start, to: end.subtract(const Duration(microseconds: 1)));

    final allExpenses = await _db.select(_db.otherExpenses).get();
    final expenses = allExpenses.where((e) => _inRange(e.expenseDate, start, end)).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final totalOtherExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    final inventoryValue = await _inventory.getTotalStockValue();

    final allOrders = await _db.select(_db.orders).get();
    final pendingOrders =
        allOrders.where((o) => o.status == 'PENDING' || o.status == 'PARTIALLY_RECEIVED').toList();

    var pendingOrderValue = 0.0;
    for (final order in pendingOrders) {
      final lines = await (_db.select(_db.orderItems)..where((t) => t.orderId.equals(order.id))).get();
      for (final line in lines) {
        final remaining = line.quantityOrdered - line.quantityReceived;
        pendingOrderValue += remaining * line.unitCost;
      }
    }

    final debtRows = await _suppliers.getSuppliersWithDebt();
    final totalOutstandingDebt = debtRows.fold(0.0, (s, r) => s + r.amountOwed);

    final grossMarginPct = totalRevenue > 0 ? (totalCommission / totalRevenue) * 100.0 : 0.0;
    final netCashFlow = totalRevenue - totalStockReceived - totalOtherExpenses;

    return FinancialSummary(
      totalRevenue: totalRevenue,
      totalCommission: totalCommission,
      totalStockReceived: totalStockReceived,
      totalOtherExpenses: totalOtherExpenses,
      inventoryValue: inventoryValue,
      pendingOrderValue: pendingOrderValue,
      pendingOrderCount: pendingOrders.length,
      grossMarginPct: grossMarginPct,
      netCashFlow: netCashFlow,
      totalOutstandingDebt: totalOutstandingDebt,
      suppliersWithDebt: debtRows,
      otherExpenses: expenses,
    );
  }

  Future<void> addExpense({required String label, required double amount, String? notes}) async {
    await _db.into(_db.otherExpenses).insert(OtherExpensesCompanion.insert(
          id: _uuid.v4(),
          label: label,
          amount: amount,
          notes: Value(notes),
        ));
    await _logs.log(ActionType.expenseCreated, 'Added expense $label GH₵${amount.toStringAsFixed(2)}');
  }

  Future<void> deleteExpense(String id, String label) async {
    await (_db.delete(_db.otherExpenses)..where((t) => t.id.equals(id))).go();
    await _logs.log(ActionType.expenseDeleted, 'Deleted expense $label');
  }

  Future<MonthlyReport> getMonthlyReport(int year, int month) async {
    final (start, end) = _monthRange(year, month);
    final items = await _inventory.getItems();

    final allStockInItems = await _db.select(_db.stockInItems).get();
    final allStockIns = await _db.select(_db.stockIns).get();
    final stockInById = {for (final s in allStockIns) s.id: s};

    final allSales = await _db.select(_db.stockOuts).get();
    final sales = allSales.where((s) => _inRange(s.dispatchedAt, start, end)).toList();

    final breakdown = <ReportBreakdownRow>[];
    var totalStockQty = 0;
    var totalStockValue = 0.0;
    var totalSalesQty = 0;
    var totalSalesValue = 0.0;

    for (final item in items) {
      var siQty = 0;
      var siVal = 0.0;
      for (final line in allStockInItems) {
        if (line.itemId != item.id) continue;
        final stockIn = stockInById[line.stockInId];
        if (stockIn == null) continue;
        if (!_inRange(stockIn.receivedDate, start, end)) continue;
        siQty += line.quantity;
        siVal += line.totalCost;
      }

      var soldQty = 0;
      var soldVal = 0.0;
      for (final s in sales) {
        if (s.itemId != item.id) continue;
        soldQty += s.quantity;
        soldVal += s.totalAmount;
      }

      if (siQty > 0 || soldQty > 0) {
        breakdown.add(ReportBreakdownRow(
          itemName: item.name,
          unit: item.unit,
          stockInQty: siQty,
          stockInValue: siVal,
          soldQty: soldQty,
          salesValue: soldVal,
        ));
      }

      totalStockQty += siQty;
      totalStockValue += siVal;
      totalSalesQty += soldQty;
      totalSalesValue += soldVal;
    }

    return MonthlyReport(
      totalStockReceivedQty: totalStockQty,
      totalStockReceivedValue: totalStockValue,
      totalSalesQty: totalSalesQty,
      totalSalesValue: totalSalesValue,
      netInventoryChange: totalStockValue - totalSalesValue,
      breakdown: breakdown,
    );
  }

  Future<DashboardData> getDashboard() async {
    final now = DateTime.now();
    final currentStart = DateTime(now.year, now.month, 1);
    final prevStart = DateTime(now.year, now.month - 1, 1);
    final prevEnd = currentStart.subtract(const Duration(microseconds: 1));

    final items = await _inventory.getItems();
    final suppliers = await _suppliers.getSuppliers();

    final allStockIns = await _db.select(_db.stockIns).get();
    final currentStockIns =
        allStockIns.where((s) => !s.receivedDate.isBefore(currentStart)).toList();
    final prevStockIns = allStockIns
        .where((s) => !s.receivedDate.isBefore(prevStart) && !s.receivedDate.isAfter(prevEnd))
        .toList();

    final currentMonthStockIn = currentStockIns.fold(0.0, (s, r) => s + r.totalCost);
    final previousMonthStockIn = prevStockIns.fold(0.0, (s, r) => s + r.totalCost);
    final currentMonthSales = await _sales.getTotalRevenue(from: currentStart);
    final previousMonthSales = await _sales.getTotalRevenue(from: prevStart, to: prevEnd);

    final lowStock = items.where((i) => i.quantity <= i.minThreshold).toList();

    final recent = allStockIns.toList()..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));
    final recentTop = recent.take(5).toList();

    final recentRows = <RecentStockInRow>[];
    for (final s in recentTop) {
      final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(s.supplierId)))
          .getSingleOrNull();
      final count = await (_db.select(_db.stockInItems)..where((t) => t.stockInId.equals(s.id))).get();
      recentRows.add(RecentStockInRow(
        id: s.id,
        referenceNumber: s.referenceNumber,
        supplierName: supplier?.name ?? 'Unknown',
        receivedDate: s.receivedDate,
        totalCost: s.totalCost,
        itemCount: count.length,
      ));
    }

    return DashboardData(
      totalItems: items.length,
      totalStockValue: await _inventory.getTotalStockValue(),
      totalSuppliers: suppliers.length,
      currentMonthStockIn: currentMonthStockIn,
      previousMonthStockIn: previousMonthStockIn,
      currentMonthSales: currentMonthSales,
      previousMonthSales: previousMonthSales,
      lowStockItems: lowStock,
      recentStockIns: recentRows,
    );
  }
}
