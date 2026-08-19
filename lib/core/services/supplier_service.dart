import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'activity_log_service.dart';
import 'order_service.dart';

const _uuid = Uuid();

class SupplierDebtRow {
  SupplierDebtRow({
    required this.id,
    required this.name,
    required this.balanceOwed,
    required this.orderDebt,
    required this.amountOwed,
  });

  final String id;
  final String name;
  final double balanceOwed;
  final double orderDebt;
  final double amountOwed;
}

class SupplierDetail {
  SupplierDetail({
    required this.supplier,
    required this.amountOwed,
    required this.stockIns,
    required this.orders,
  });

  final Supplier supplier;
  final double amountOwed;
  final List<StockIn> stockIns;
  final List<OrderWithItems> orders;
}

class ExpenseLineInput {
  ExpenseLineInput({required this.label, required this.amount});
  final String label;
  final double amount;
}

class SupplierService {
  SupplierService(this._db, this._logs, this._orders);
  final AppDatabase _db;
  final ActivityLogService _logs;
  final OrderService _orders;

  Future<List<Supplier>> getSuppliers() =>
      (_db.select(_db.suppliers)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Supplier?> getSupplier(String id) =>
      (_db.select(_db.suppliers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> createSupplier({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    double balanceOwed = 0,
  }) async {
    await _db.into(_db.suppliers).insert(SuppliersCompanion.insert(
          id: _uuid.v4(),
          name: name,
          contactPerson: Value(contactPerson),
          phone: Value(phone),
          email: Value(email),
          address: Value(address),
          balanceOwed: Value(balanceOwed),
        ));
    await _logs.log(ActionType.supplierCreated, 'Created supplier $name');
  }

  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
  }) async {
    await (_db.update(_db.suppliers)..where((t) => t.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(name),
        contactPerson: Value(contactPerson),
        phone: Value(phone),
        email: Value(email),
        address: Value(address),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _logs.log(ActionType.supplierEdited, 'Updated supplier $name');
  }

  Future<void> deleteSupplier(String id, String name) async {
    await (_db.delete(_db.suppliers)..where((t) => t.id.equals(id))).go();
    await _logs.log(ActionType.supplierDeleted, 'Deleted supplier $name');
  }

  double _pendingOrderDebt(List<OrderWithItems> supplierOrders) {
    var debt = 0.0;
    for (final o in supplierOrders) {
      if (o.order.status == 'CANCELLED' || o.order.status == 'RECEIVED') continue;
      for (final line in o.items) {
        final remaining = line.line.quantityOrdered - line.line.quantityReceived;
        debt += remaining * line.line.unitCost;
      }
    }
    return debt;
  }

  Future<List<SupplierDebtRow>> getSuppliersWithDebt() async {
    final suppliers = await getSuppliers();
    final allOrders = await _orders.getOrders();
    return suppliers.map((s) {
      final supplierOrders = allOrders.where((o) => o.order.supplierId == s.id).toList();
      final orderDebt = _pendingOrderDebt(supplierOrders);
      return SupplierDebtRow(
        id: s.id,
        name: s.name,
        balanceOwed: s.balanceOwed,
        orderDebt: orderDebt,
        amountOwed: s.balanceOwed + orderDebt,
      );
    }).where((r) => r.amountOwed > 0).toList();
  }

  Future<SupplierDetail> getSupplierDetail(String id) async {
    final supplier = await getSupplier(id);
    if (supplier == null) throw Exception('Supplier not found');

    final stockIns = await (_db.select(_db.stockIns)
          ..where((t) => t.supplierId.equals(id))
          ..orderBy([(t) => OrderingTerm.desc(t.receivedDate)]))
        .get();

    final allOrders = await _orders.getOrders();
    final supplierOrders = allOrders.where((o) => o.order.supplierId == id).toList();
    final orderDebt = _pendingOrderDebt(supplierOrders);

    return SupplierDetail(
      supplier: supplier,
      amountOwed: supplier.balanceOwed + orderDebt,
      stockIns: stockIns,
      orders: supplierOrders,
    );
  }

  Future<void> payDebt({
    required String supplierId,
    required double amount,
    String? notes,
  }) async {
    final supplier = await getSupplier(supplierId);
    if (supplier == null) throw Exception('Supplier not found');
    if (amount <= 0) throw Exception('Amount must be positive');

    await (_db.update(_db.suppliers)..where((t) => t.id.equals(supplierId))).write(
      SuppliersCompanion(
        balanceOwed: Value((supplier.balanceOwed - amount).clamp(0, double.infinity)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _logs.log(
      ActionType.supplierPayment,
      'Paid GH₵${amount.toStringAsFixed(2)} to ${supplier.name}${notes != null ? ' — $notes' : ''}',
    );
  }

  Future<void> settle({
    required String supplierId,
    required double goodsCost,
    required double amountPaid,
    List<ExpenseLineInput> expenses = const [],
    String? notes,
    required String context,
    required String referenceLabel,
  }) async {
    final supplier = await getSupplier(supplierId);
    if (supplier == null) throw Exception('Supplier not found');

    final extraExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    final totalOwed = goodsCost + extraExpenses;
    final debtAdded = (totalOwed - amountPaid).clamp(0, double.infinity);

    await _db.transaction(() async {
      if (debtAdded > 0) {
        await (_db.update(_db.suppliers)..where((t) => t.id.equals(supplierId))).write(
          SuppliersCompanion(
            balanceOwed: Value(supplier.balanceOwed + debtAdded),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      for (final exp in expenses) {
        if (exp.amount > 0) {
          await _db.into(_db.otherExpenses).insert(OtherExpensesCompanion.insert(
                id: _uuid.v4(),
                label: exp.label.isEmpty ? 'Supplier expense' : exp.label,
                amount: exp.amount,
                notes: Value('$referenceLabel — ${supplier.name}'),
              ));
        }
      }

      await _logs.log(
        ActionType.supplierPayment,
        'Settle ($context): $referenceLabel — paid GH₵${amountPaid.toStringAsFixed(2)} of GH₵${totalOwed.toStringAsFixed(2)}${notes != null ? ' — $notes' : ''}',
      );
    });
  }
}
