import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get balanceOwed => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get supplierId => text().nullable().references(Suppliers, #id)();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get minThreshold => integer().withDefault(const Constant(5))();
  TextColumn get location => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get orderNumber => text()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expectedDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  TextColumn get notes => text().nullable()();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get quantityOrdered => integer()();
  IntColumn get quantityReceived => integer().withDefault(const Constant(0))();
  RealColumn get unitCost => real()();
  RealColumn get totalCost => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockIns extends Table {
  TextColumn get id => text()();
  TextColumn get referenceNumber => text()();
  TextColumn get supplierId => text().references(Suppliers, #id)();
  TextColumn get orderId => text().nullable().references(Orders, #id)();
  DateTimeColumn get receivedDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  RealColumn get totalCost => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockInItems extends Table {
  TextColumn get id => text()();
  TextColumn get stockInId => text().references(StockIns, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitCost => real()();
  RealColumn get totalCost => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StockOuts extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get quantity => integer()();
  RealColumn get sellingPrice => real()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
  RealColumn get profit => real().withDefault(const Constant(0))();
  TextColumn get discountType => text().withDefault(const Constant('NONE'))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  TextColumn get saleReference => text().nullable()();
  TextColumn get customerReference => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dispatchedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OtherExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get action => text()();
  TextColumn get details => text()();
  IntColumn get quantityChange => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
