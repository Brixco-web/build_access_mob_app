import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'activity_log_service.dart';

const _uuid = Uuid();

class SaleLineInput {
  SaleLineInput({
    required this.itemId,
    required this.quantity,
    required this.sellingPrice,
    this.costPrice,
  });

  final String itemId;
  final int quantity;
  final double sellingPrice;
  final double? costPrice;
}

class DiscountInput {
  const DiscountInput({
    this.type = DiscountType.none,
    this.moneyAmount = 0,
    this.freeItemId,
    this.freeQuantity = 1,
  });

  final DiscountType type;
  final double moneyAmount;
  final String? freeItemId;
  final int freeQuantity;
}

class SaleResult {
  SaleResult({
    required this.saleReference,
    required this.stockOutIds,
    required this.totalAmount,
    required this.lines,
  });

  final String saleReference;
  final List<String> stockOutIds;
  final double totalAmount;
  final List<SaleLineResult> lines;
}

class SaleLineResult {
  SaleLineResult({
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.sellingPrice,
    required this.lineTotal,
  });

  final String itemName;
  final String unit;
  final int quantity;
  final double sellingPrice;
  final double lineTotal;
}

class SalesService {
  SalesService(this._db, this._logs);
  final AppDatabase _db;
  final ActivityLogService _logs;

  Future<String> _nextSaleReference() async {
    final counterStr = await _db.getSetting('receiptCounter') ?? '0';
    final next = int.tryParse(counterStr) ?? 0;
    final ref = 'SL-${(next + 1).toString().padLeft(5, '0')}';
    await _db.setSetting('receiptCounter', '${next + 1}');
    return ref;
  }

  Stream<List<StockOut>> watchSales() {
    return (_db.select(_db.stockOuts)
          ..orderBy([
            (t) => OrderingTerm.desc(t.dispatchedAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<StockOut>> getSales() => watchSales().first;

  Future<List<StockOut>> getSalesByReference(String saleReference) async {
    return (_db.select(_db.stockOuts)..where((t) => t.saleReference.equals(saleReference))).get();
  }

  Future<SaleResult> recordSale({
    required List<SaleLineInput> lines,
    required DateTime dispatchedAt,
    String? customerReference,
    String? notes,
    DiscountInput discount = const DiscountInput(),
  }) async {
    if (lines.isEmpty) throw Exception('At least one item required');

    for (final line in lines) {
      final item = await (_db.select(_db.items)..where((t) => t.id.equals(line.itemId)))
          .getSingleOrNull();
      if (item == null) throw Exception('Item not found');
      if (item.quantity < line.quantity) {
        throw Exception('Not enough stock for ${item.name} (available: ${item.quantity})');
      }
    }

    final saleReference = await _nextSaleReference();
    final stockOutIds = <String>[];
    final resultLines = <SaleLineResult>[];
    var grandTotal = 0.0;
    var discountApplied = false;

    await _db.transaction(() async {
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final item = await (_db.select(_db.items)..where((t) => t.id.equals(line.itemId)))
            .getSingleOrNull();
        if (item == null) continue;

        final sellingPrice = line.sellingPrice;
        final costPrice = line.costPrice ?? item.costPrice;
        var totalAmount = sellingPrice * line.quantity;
        var profit = (sellingPrice - costPrice) * line.quantity;

        var discountType = DiscountType.none;
        var discountAmount = 0.0;

        if (!discountApplied && discount.type == DiscountType.money && discount.moneyAmount > 0) {
          discountType = DiscountType.money;
          discountAmount = discount.moneyAmount;
          totalAmount = (totalAmount - discountAmount).clamp(0, double.infinity);
          profit = (profit - discountAmount).clamp(-costPrice * line.quantity, double.infinity);
          discountApplied = true;
        }

        final stockOutId = _uuid.v4();
        await _db.into(_db.stockOuts).insert(StockOutsCompanion.insert(
              id: stockOutId,
              itemId: line.itemId,
              quantity: line.quantity,
              sellingPrice: sellingPrice,
              costPrice: Value(costPrice),
              totalAmount: totalAmount,
              profit: Value(profit),
              discountType: Value(discountTypeDb(discountType)),
              discountAmount: Value(discountAmount),
              saleReference: Value(saleReference),
              customerReference: Value(customerReference),
              notes: Value(notes),
              dispatchedAt: Value(dispatchedAt),
            ));

        await (_db.update(_db.items)..where((t) => t.id.equals(line.itemId))).write(
          ItemsCompanion(
            quantity: Value(item.quantity - line.quantity),
            updatedAt: Value(DateTime.now()),
          ),
        );

        stockOutIds.add(stockOutId);
        grandTotal += totalAmount;
        resultLines.add(SaleLineResult(
          itemName: item.name,
          unit: item.unit,
          quantity: line.quantity,
          sellingPrice: sellingPrice,
          lineTotal: totalAmount,
        ));

        await _logs.log(
          ActionType.stockOut,
          'Sold ${line.quantity} of ${item.name} (GH₵${totalAmount.toStringAsFixed(2)})',
          quantityChange: -line.quantity,
        );
      }

      if (discount.type == DiscountType.freeItem &&
          discount.freeItemId != null &&
          discount.freeQuantity > 0) {
        final freeItem = await (_db.select(_db.items)
              ..where((t) => t.id.equals(discount.freeItemId!)))
            .getSingleOrNull();
        if (freeItem != null && freeItem.quantity >= discount.freeQuantity) {
          final stockOutId = _uuid.v4();
          await _db.into(_db.stockOuts).insert(StockOutsCompanion.insert(
                id: stockOutId,
                itemId: freeItem.id,
                quantity: discount.freeQuantity,
                sellingPrice: 0,
                costPrice: Value(freeItem.costPrice),
                totalAmount: 0,
                profit: Value(-freeItem.costPrice * discount.freeQuantity),
                discountType: const Value('FREE_ITEM'),
                saleReference: Value(saleReference),
                customerReference: Value(customerReference),
                notes: const Value('Free item discount'),
                dispatchedAt: Value(dispatchedAt),
              ));
          await (_db.update(_db.items)..where((t) => t.id.equals(freeItem.id))).write(
            ItemsCompanion(
              quantity: Value(freeItem.quantity - discount.freeQuantity),
              updatedAt: Value(DateTime.now()),
            ),
          );
          stockOutIds.add(stockOutId);
          await _logs.log(
            ActionType.stockOut,
            'Free item: ${discount.freeQuantity} of ${freeItem.name}',
            quantityChange: -discount.freeQuantity,
          );
        }
      }
    });

    return SaleResult(
      saleReference: saleReference,
      stockOutIds: stockOutIds,
      totalAmount: grandTotal,
      lines: resultLines,
    );
  }

  Future<void> deleteSale(String id) async {
    await _db.transaction(() async {
      final sale = await (_db.select(_db.stockOuts)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (sale == null) return;

      final item = await (_db.select(_db.items)..where((t) => t.id.equals(sale.itemId)))
          .getSingleOrNull();
      if (item != null) {
        await (_db.update(_db.items)..where((t) => t.id.equals(sale.itemId))).write(
          ItemsCompanion(
            quantity: Value(item.quantity + sale.quantity),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await (_db.delete(_db.stockOuts)..where((t) => t.id.equals(id))).go();
      await _logs.log(ActionType.stockOutDeleted, 'Deleted sale record');
    });
  }

  Future<double> getTotalRevenue({DateTime? from, DateTime? to}) async {
    final sales = await _db.select(_db.stockOuts).get();
    return sales.where((s) {
      if (from != null && s.dispatchedAt.isBefore(from)) return false;
      if (to != null && s.dispatchedAt.isAfter(to)) return false;
      return true;
    }).fold<double>(0.0, (sum, s) => sum + s.totalAmount);
  }

  Future<double> getTotalProfit({DateTime? from, DateTime? to}) async {
    final sales = await _db.select(_db.stockOuts).get();
    return sales.where((s) {
      if (from != null && s.dispatchedAt.isBefore(from)) return false;
      if (to != null && s.dispatchedAt.isAfter(to)) return false;
      return true;
    }).fold<double>(0.0, (sum, s) => sum + s.profit);
  }
}
