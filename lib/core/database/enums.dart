enum OrderStatus { pending, partiallyReceived, received, cancelled }

enum DiscountType { none, money, freeItem }

enum ActionType {
  stockIn,
  stockOut,
  itemCreated,
  itemEdited,
  itemDeleted,
  priceChanged,
  supplierCreated,
  supplierEdited,
  supplierDeleted,
  supplierPayment,
  orderCreated,
  orderReceived,
  orderCancelled,
  expenseCreated,
  expenseDeleted,
  stockInDeleted,
  stockOutDeleted,
}

String orderStatusLabel(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.partiallyReceived:
      return 'Partial';
    case OrderStatus.received:
      return 'Received';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

String discountTypeDb(DiscountType t) {
  switch (t) {
    case DiscountType.none:
      return 'NONE';
    case DiscountType.money:
      return 'MONEY';
    case DiscountType.freeItem:
      return 'FREE_ITEM';
  }
}

DiscountType discountTypeFromDb(String v) {
  switch (v) {
    case 'MONEY':
      return DiscountType.money;
    case 'FREE_ITEM':
      return DiscountType.freeItem;
    default:
      return DiscountType.none;
  }
}

String orderStatusDb(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return 'PENDING';
    case OrderStatus.partiallyReceived:
      return 'PARTIALLY_RECEIVED';
    case OrderStatus.received:
      return 'RECEIVED';
    case OrderStatus.cancelled:
      return 'CANCELLED';
  }
}

OrderStatus orderStatusFromDb(String v) {
  switch (v) {
    case 'PARTIALLY_RECEIVED':
      return OrderStatus.partiallyReceived;
    case 'RECEIVED':
      return OrderStatus.received;
    case 'CANCELLED':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}
