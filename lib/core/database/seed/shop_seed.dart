import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../app_database.dart';

const _uuid = Uuid();

/// Seeds categories, suppliers, and items from web seed.ts (no user accounts).
Future<void> seedShopData(AppDatabase db) async {
  if (await db.isSeeded()) return;

  final catFasteners = _uuid.v4();
  final catSealants = _uuid.v4();
  final catHardware = _uuid.v4();
  final catElectrical = _uuid.v4();

  await db.batch((b) {
    b.insertAll(db.categories, [
      CategoriesCompanion.insert(
        id: catFasteners,
        name: 'Fasteners & Screws',
        description: const Value('Bolts, nuts, screws, and anchors'),
      ),
      CategoriesCompanion.insert(
        id: catSealants,
        name: 'Sealants & Adhesives',
        description: const Value('Silicone sealants, foam, and structural glues'),
      ),
      CategoriesCompanion.insert(
        id: catHardware,
        name: 'Door & Window Hardware',
        description: const Value('Hinges, locks, handles, and stays'),
      ),
      CategoriesCompanion.insert(
        id: catElectrical,
        name: 'Electrical Fittings',
        description: const Value('Conduits, junction boxes, cable clips'),
      ),
    ]);
  });

  final sup1 = _uuid.v4();
  final sup2 = _uuid.v4();

  await db.batch((b) {
    b.insertAll(db.suppliers, [
      SuppliersCompanion.insert(
        id: sup1,
        name: 'Apex Hardware Wholesale',
        contactPerson: const Value('Kwame Asante'),
        phone: const Value('0244000111'),
        email: const Value('kwame@apexwholesale.com'),
        address: const Value('Suame Magazine, Kumasi'),
      ),
      SuppliersCompanion.insert(
        id: sup2,
        name: 'BuildRight Supplies Ghana',
        contactPerson: const Value('Ama Osei'),
        phone: const Value('0302000222'),
        email: const Value('ama@buildright.gh'),
        address: const Value('Tema Industrial Area, Accra'),
      ),
    ]);
  });

  await db.batch((b) {
    b.insertAll(db.items, [
      ItemsCompanion.insert(
        id: 'item-bolt-m6',
        name: 'M6 x 40mm Hex Stainless Bolt',
        categoryId: catFasteners,
        supplierId: Value(sup1),
        unit: const Value('pcs'),
        costPrice: const Value(2.50),
        sellingPrice: const Value(4.00),
        quantity: const Value(500),
        minThreshold: const Value(100),
        location: const Value('Shelf A1'),
      ),
      ItemsCompanion.insert(
        id: 'item-silicone-clr',
        name: 'Clear Weatherproof Silicone 300ml',
        categoryId: catSealants,
        supplierId: Value(sup1),
        unit: const Value('tube'),
        costPrice: const Value(18.00),
        sellingPrice: const Value(28.00),
        quantity: const Value(8),
        minThreshold: const Value(15),
        location: const Value('Shelf B2'),
      ),
      ItemsCompanion.insert(
        id: 'item-hinge-100',
        name: '100mm Heavy Duty Aluminum Hinge',
        categoryId: catHardware,
        supplierId: Value(sup2),
        unit: const Value('pair'),
        costPrice: const Value(35.00),
        sellingPrice: const Value(55.00),
        quantity: const Value(45),
        minThreshold: const Value(10),
        location: const Value('Shelf C3'),
      ),
      ItemsCompanion.insert(
        id: 'item-conduit-20',
        name: '20mm PVC Conduit Pipe 3m',
        categoryId: catElectrical,
        supplierId: Value(sup2),
        unit: const Value('length'),
        costPrice: const Value(12.00),
        sellingPrice: const Value(18.00),
        quantity: const Value(60),
        minThreshold: const Value(20),
        location: const Value('Shelf D1'),
      ),
      ItemsCompanion.insert(
        id: 'item-anchor-8',
        name: '8mm Wall Anchor Pack (50pcs)',
        categoryId: catFasteners,
        supplierId: Value(sup1),
        unit: const Value('pack'),
        costPrice: const Value(25.00),
        sellingPrice: const Value(40.00),
        quantity: const Value(30),
        minThreshold: const Value(10),
        location: const Value('Shelf A2'),
      ),
      ItemsCompanion.insert(
        id: 'item-foam-gun',
        name: 'Expanding Foam Gun Applicator',
        categoryId: catSealants,
        supplierId: Value(sup1),
        unit: const Value('pcs'),
        costPrice: const Value(45.00),
        sellingPrice: const Value(70.00),
        quantity: const Value(12),
        minThreshold: const Value(5),
        location: const Value('Shelf B1'),
      ),
      ItemsCompanion.insert(
        id: 'item-lock-dead',
        name: 'Deadbolt Door Lock Set',
        categoryId: catHardware,
        supplierId: Value(sup2),
        unit: const Value('set'),
        costPrice: const Value(85.00),
        sellingPrice: const Value(130.00),
        quantity: const Value(18),
        minThreshold: const Value(5),
        location: const Value('Shelf C1'),
      ),
      ItemsCompanion.insert(
        id: 'item-junction',
        name: '4-Way Junction Box',
        categoryId: catElectrical,
        supplierId: Value(sup2),
        unit: const Value('pcs'),
        costPrice: const Value(8.00),
        sellingPrice: const Value(14.00),
        quantity: const Value(75),
        minThreshold: const Value(25),
        location: const Value('Shelf D2'),
      ),
    ]);
  });

  await db.setSetting('shopName', 'Apex Building Accessories');
  await db.setSetting('receiptCounter', '0');
  await db.markSeeded();
}
