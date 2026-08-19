import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/seed/shop_seed.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final databaseInitProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await seedShopData(db);
});

final shopNameProvider = FutureProvider<String>((ref) async {
  await ref.watch(databaseInitProvider.future);
  final db = ref.watch(databaseProvider);
  return await db.getSetting('shopName') ?? 'Apex Building Accessories';
});
