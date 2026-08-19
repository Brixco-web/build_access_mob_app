import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Categories,
  Suppliers,
  Items,
  Orders,
  OrderItems,
  StockIns,
  StockInItems,
  StockOuts,
  OtherExpenses,
  ActivityLogs,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'apex_shop.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<bool> isSeeded() async {
    return (await getSetting('isSeeded')) == 'true';
  }

  Future<void> markSeeded() async {
    await setSetting('isSeeded', 'true');
  }
}
