import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'activity_log_service.dart';

const _uuid = Uuid();

class InventoryService {
  InventoryService(this._db, this._logs);
  final AppDatabase _db;
  final ActivityLogService _logs;

  Stream<List<Item>> watchItems() {
    return (_db.select(_db.items)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Future<List<Category>> getCategories() => _db.select(_db.categories).get();

  Future<List<Item>> getItems() =>
      (_db.select(_db.items)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  Future<Item?> getItem(String id) =>
      (_db.select(_db.items)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Item>> getLowStockItems() async {
    final items = await getItems();
    return items.where((i) => i.quantity <= i.minThreshold).toList();
  }

  Future<void> createItem({
    required String name,
    required String categoryId,
    String? supplierId,
    String unit = 'pcs',
    required double costPrice,
    required double sellingPrice,
    int quantity = 0,
    int minThreshold = 5,
    String? location,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.items).insert(ItemsCompanion.insert(
          id: id,
          name: name,
          categoryId: categoryId,
          supplierId: Value(supplierId),
          unit: Value(unit),
          costPrice: Value(costPrice),
          sellingPrice: Value(sellingPrice),
          quantity: Value(quantity),
          minThreshold: Value(minThreshold),
          location: Value(location),
        ));
    await _logs.log(ActionType.itemCreated, 'Created item $name', quantityChange: quantity);
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required String categoryId,
    String? supplierId,
    required String unit,
    required double costPrice,
    required double sellingPrice,
    required int minThreshold,
    String? location,
  }) async {
    await (_db.update(_db.items)..where((t) => t.id.equals(id))).write(ItemsCompanion(
          name: Value(name),
          categoryId: Value(categoryId),
          supplierId: Value(supplierId),
          unit: Value(unit),
          costPrice: Value(costPrice),
          sellingPrice: Value(sellingPrice),
          minThreshold: Value(minThreshold),
          location: Value(location),
          updatedAt: Value(DateTime.now()),
        ));
    await _logs.log(ActionType.itemEdited, 'Updated item $name');
  }

  Future<void> deleteItem(String id, String name) async {
    await (_db.delete(_db.items)..where((t) => t.id.equals(id))).go();
    await _logs.log(ActionType.itemDeleted, 'Deleted item $name');
  }

  Future<void> restock({
    required String itemId,
    required int quantity,
    required double unitCost,
    double? sellingPrice,
    required String supplierId,
    String? referenceNumber,
    String? notes,
  }) async {
    await _db.transaction(() async {
      final item = await getItem(itemId);
      if (item == null) throw Exception('Item not found');

      final ref = referenceNumber ?? 'RST-${DateTime.now().millisecondsSinceEpoch}';
      final stockInId = _uuid.v4();
      final totalCost = quantity * unitCost;

      await _db.into(_db.stockIns).insert(StockInsCompanion.insert(
            id: stockInId,
            referenceNumber: ref,
            supplierId: supplierId,
            notes: Value(notes ?? 'Restock ${item.name}'),
            totalCost: Value(totalCost),
          ));

      await _db.into(_db.stockInItems).insert(StockInItemsCompanion.insert(
            id: _uuid.v4(),
            stockInId: stockInId,
            itemId: itemId,
            quantity: quantity,
            unitCost: unitCost,
            totalCost: totalCost,
          ));

      await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(ItemsCompanion(
            quantity: Value(item.quantity + quantity),
            costPrice: Value(unitCost),
            sellingPrice: sellingPrice != null ? Value(sellingPrice) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ));

      await _logs.log(
        ActionType.stockIn,
        'Restocked $quantity of ${item.name} via $ref',
        quantityChange: quantity,
      );
    });
  }

  Future<double> getTotalStockValue() async {
    final items = await getItems();
    return items.fold<double>(0.0, (sum, i) => sum + i.quantity * i.costPrice);
  }
}
