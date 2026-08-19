import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/enums.dart';

const _uuid = Uuid();

class ActivityLogService {
  ActivityLogService(this._db);
  final AppDatabase _db;

  Future<void> log(ActionType action, String details, {int? quantityChange}) async {
    await _db.into(_db.activityLogs).insert(
          ActivityLogsCompanion.insert(
            id: _uuid.v4(),
            action: actionTypeDb(action),
            details: details,
            quantityChange: Value(quantityChange),
          ),
        );
  }

  Future<List<ActivityLog>> getAll({String? actionFilter, String? search}) async {
    var query = _db.select(_db.activityLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    final rows = await query.get();
    return rows.where((r) {
      if (actionFilter != null && actionFilter != 'ALL' && r.action != actionFilter) {
        return false;
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        return r.details.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }
}

String actionTypeDb(ActionType a) {
  const map = {
    ActionType.stockIn: 'STOCK_IN',
    ActionType.stockOut: 'STOCK_OUT',
    ActionType.itemCreated: 'ITEM_CREATED',
    ActionType.itemEdited: 'ITEM_EDITED',
    ActionType.itemDeleted: 'ITEM_DELETED',
    ActionType.priceChanged: 'PRICE_CHANGED',
    ActionType.supplierCreated: 'SUPPLIER_CREATED',
    ActionType.supplierEdited: 'SUPPLIER_EDITED',
    ActionType.supplierDeleted: 'SUPPLIER_DELETED',
    ActionType.supplierPayment: 'SUPPLIER_PAYMENT',
    ActionType.orderCreated: 'ORDER_CREATED',
    ActionType.orderReceived: 'ORDER_RECEIVED',
    ActionType.orderCancelled: 'ORDER_CANCELLED',
    ActionType.expenseCreated: 'EXPENSE_CREATED',
    ActionType.expenseDeleted: 'EXPENSE_DELETED',
    ActionType.stockInDeleted: 'STOCK_IN_DELETED',
    ActionType.stockOutDeleted: 'STOCK_OUT_DELETED',
  };
  return map[a] ?? a.name.toUpperCase();
}
