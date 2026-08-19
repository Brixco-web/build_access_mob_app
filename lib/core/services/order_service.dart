import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/enums.dart';
import 'activity_log_service.dart';

const _uuid = Uuid();

class OrderLineInput {
  OrderLineInput({required this.itemId, required this.quantity, required this.unitCost});
  final String itemId;
  final int quantity;
  final double unitCost;
}

class OrderWithItems {
  OrderWithItems({required this.order, required this.items, required this.supplierName});
  final Order order;
  final List<OrderItemWithName> items;
  final String supplierName;
}

class OrderItemWithName {
  OrderItemWithName({required this.line, required this.itemName, required this.unit});
  final OrderItem line;
  final String itemName;
  final String unit;
}

class ReceiveLineInput {
  ReceiveLineInput({required this.itemId, required this.quantity, this.sellingPrice});
  final String itemId;
  final int quantity;
  final double? sellingPrice;
}

class OrderService {
  OrderService(this._db, this._logs);
  final AppDatabase _db;
  final ActivityLogService _logs;

  Future<List<OrderWithItems>> getOrders() async {
    final orders = await (_db.select(_db.orders)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    final result = <OrderWithItems>[];
    for (final order in orders) {
      result.add(await _loadOrderWithItems(order));
    }
    return result;
  }

  Future<OrderWithItems?> getOrder(String id) async {
    final order = await (_db.select(_db.orders)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (order == null) return null;
    return _loadOrderWithItems(order);
  }

  Future<OrderWithItems> _loadOrderWithItems(Order order) async {
    final supplier = await (_db.select(_db.suppliers)..where((t) => t.id.equals(order.supplierId)))
        .getSingleOrNull();
    final lines = await (_db.select(_db.orderItems)..where((t) => t.orderId.equals(order.id))).get();
    final items = <OrderItemWithName>[];
    for (final line in lines) {
      final item = await (_db.select(_db.items)..where((t) => t.id.equals(line.itemId)))
          .getSingleOrNull();
      items.add(OrderItemWithName(
        line: line,
        itemName: item?.name ?? 'Unknown',
        unit: item?.unit ?? 'pcs',
      ));
    }
    return OrderWithItems(
      order: order,
      items: items,
      supplierName: supplier?.name ?? 'Unknown',
    );
  }

  Future<OrderWithItems> placeOrder({
    required String orderNumber,
    required String supplierId,
    required List<OrderLineInput> lines,
    DateTime? orderDate,
    DateTime? expectedDate,
    String? notes,
  }) async {
    if (lines.isEmpty) throw Exception('At least one item required');

    var totalCost = 0.0;
    for (final l in lines) {
      totalCost += l.quantity * l.unitCost;
    }

    final orderId = _uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.orders).insert(OrdersCompanion.insert(
            id: orderId,
            orderNumber: orderNumber,
            supplierId: supplierId,
            orderDate: Value(orderDate ?? DateTime.now()),
            expectedDate: Value(expectedDate),
            notes: Value(notes),
            totalCost: Value(totalCost),
          ));

      for (final line in lines) {
        await _db.into(_db.orderItems).insert(OrderItemsCompanion.insert(
              id: _uuid.v4(),
              orderId: orderId,
              itemId: line.itemId,
              quantityOrdered: line.quantity,
              unitCost: line.unitCost,
              totalCost: line.quantity * line.unitCost,
            ));
      }

      await _logs.log(
        ActionType.orderCreated,
        'Placed order $orderNumber for ${lines.length} items',
      );
    });

    return (await getOrder(orderId))!;
  }

  Future<void> cancelOrder(String orderId, String orderNumber) async {
    await (_db.update(_db.orders)..where((t) => t.id.equals(orderId))).write(
      OrdersCompanion(
        status: const Value('CANCELLED'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await _logs.log(ActionType.orderCancelled, 'Cancelled order $orderNumber');
  }

  Future<double> receiveOrder({
    required String orderId,
    required String referenceNumber,
    required List<ReceiveLineInput> lines,
    DateTime? receivedDate,
    String? notes,
  }) async {
    final orderData = await getOrder(orderId);
    if (orderData == null) throw Exception('Order not found');
    if (orderData.order.status == 'CANCELLED' || orderData.order.status == 'RECEIVED') {
      throw Exception('Order cannot be received');
    }

    var totalCost = 0.0;
    var totalQty = 0;

    await _db.transaction(() async {
      for (final incoming in lines) {
        final orderLine = orderData.items.firstWhere(
          (i) => i.line.itemId == incoming.itemId,
          orElse: () => throw Exception('Invalid order line'),
        );
        final remaining = orderLine.line.quantityOrdered - orderLine.line.quantityReceived;
        if (incoming.quantity <= 0 || incoming.quantity > remaining) {
          throw Exception('Invalid receive quantity for ${orderLine.itemName}');
        }
        totalCost += incoming.quantity * orderLine.line.unitCost;
        totalQty += incoming.quantity;
      }

      final stockInId = _uuid.v4();
      await _db.into(_db.stockIns).insert(StockInsCompanion.insert(
            id: stockInId,
            referenceNumber: referenceNumber,
            supplierId: orderData.order.supplierId,
            orderId: Value(orderId),
            notes: Value(notes ?? 'Received from order ${orderData.order.orderNumber}'),
            totalCost: Value(totalCost),
            receivedDate: Value(receivedDate ?? DateTime.now()),
          ));

      for (final incoming in lines) {
        final orderLine = orderData.items.firstWhere((i) => i.line.itemId == incoming.itemId);
        await _db.into(_db.stockInItems).insert(StockInItemsCompanion.insert(
              id: _uuid.v4(),
              stockInId: stockInId,
              itemId: incoming.itemId,
              quantity: incoming.quantity,
              unitCost: orderLine.line.unitCost,
              totalCost: incoming.quantity * orderLine.line.unitCost,
            ));

        final item = await (_db.select(_db.items)..where((t) => t.id.equals(incoming.itemId)))
            .getSingleOrNull();
        if (item != null) {
          await (_db.update(_db.items)..where((t) => t.id.equals(incoming.itemId))).write(
            ItemsCompanion(
              quantity: Value(item.quantity + incoming.quantity),
              sellingPrice: incoming.sellingPrice != null
                  ? Value(incoming.sellingPrice!)
                  : const Value.absent(),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }

        await (_db.update(_db.orderItems)
              ..where((t) => t.orderId.equals(orderId) & t.itemId.equals(incoming.itemId)))
            .write(OrderItemsCompanion(
              quantityReceived: Value(orderLine.line.quantityReceived + incoming.quantity),
            ));
      }

      final updatedLines = await (_db.select(_db.orderItems)
            ..where((t) => t.orderId.equals(orderId)))
          .get();
      final allReceived = updatedLines.every((i) => i.quantityReceived >= i.quantityOrdered);
      final anyReceived = updatedLines.any((i) => i.quantityReceived > 0);
      final newStatus = allReceived
          ? 'RECEIVED'
          : anyReceived
              ? 'PARTIALLY_RECEIVED'
              : 'PENDING';

      await (_db.update(_db.orders)..where((t) => t.id.equals(orderId))).write(
        OrdersCompanion(status: Value(newStatus), updatedAt: Value(DateTime.now())),
      );

      await _logs.log(
        ActionType.orderReceived,
        'Received $totalQty items from order ${orderData.order.orderNumber}',
        quantityChange: totalQty,
      );
    });

    return totalCost;
  }
}
