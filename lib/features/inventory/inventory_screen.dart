import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/services_provider.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';
import '../../shared/widgets/number_field.dart';
import '../../shared/widgets/payment_settle_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _search = '';
  String _categoryFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsStreamProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      body: itemsAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final categories = categoriesAsync.value ?? [];
          final filtered = items.where((i) {
            final matchSearch = i.name.toLowerCase().contains(_search.toLowerCase());
            final matchCat = _categoryFilter == 'ALL' || i.categoryId == _categoryFilter;
            return matchSearch && matchCat;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Inventory', style: Theme.of(context).textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: () => _openItemForm(context, categories, suppliersAsync.value ?? []),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _categoryFilter == 'ALL',
                            onSelected: (_) => setState(() => _categoryFilter = 'ALL'),
                          ),
                          ...categories.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: FilterChip(
                                label: Text(c.name),
                                selected: _categoryFilter == c.id,
                                onSelected: (_) => setState(() => _categoryFilter = c.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No items found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, idx) {
                          final item = filtered[idx];
                          final low = item.quantity <= item.minThreshold;
                          return ApexCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    if (low)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.dangerBg,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: const Text('LOW',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.danger)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.quantity} ${item.unit} in stock'),
                                    GhcText(item.sellingPrice, bold: true),
                                  ],
                                ),
                                Text('Cost: ${item.costPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _openRestock(context, item, suppliersAsync.value ?? []),
                                      icon: const Icon(LucideIcons.packagePlus, size: 16),
                                      label: const Text('Restock'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openItemForm(context, categories, suppliersAsync.value ?? [], item: item),
                                      icon: const Icon(LucideIcons.pencil, size: 16),
                                      label: const Text('Edit'),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                      onPressed: () => _deleteItem(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteItem(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(inventoryServiceProvider).deleteItem(item.id, item.name);
    }
  }

  Future<void> _openItemForm(
    BuildContext context,
    List<Category> categories,
    List<Supplier> suppliers, {
    Item? item,
  }) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    var categoryId = item?.categoryId ?? (categories.isNotEmpty ? categories.first.id : '');
    var supplierId = item?.supplierId;
    var unit = item?.unit ?? 'pcs';
    var qty = item?.quantity.toDouble() ?? 0;
    var cost = item?.costPrice ?? 0.0;
    var sell = item?.sellingPrice ?? 0.0;
    var minT = item?.minThreshold.toDouble() ?? 5;
    final locCtrl = TextEditingController(text: item?.location ?? '');

    await showApexModal(
      context: context,
      title: item == null ? 'Add Item' : 'Edit Item',
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Item name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: categoryId.isEmpty ? null : categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setModal(() => categoryId = v ?? categoryId),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: supplierId,
              decoration: const InputDecoration(labelText: 'Supplier (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
              ],
              onChanged: (v) => setModal(() => supplierId = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: NumberField(label: 'Qty', value: qty, integer: true, onChanged: (v) => qty = v)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Unit'),
                    controller: TextEditingController(text: unit),
                    onChanged: (v) => unit = v,
                  ),
                ),
              ],
            ),
            NumberField(label: 'Cost price', value: cost, onChanged: (v) => cost = v),
            NumberField(label: 'Selling price', value: sell, onChanged: (v) => sell = v),
            NumberField(label: 'Min threshold', value: minT, integer: true, onChanged: (v) => minT = v),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || categoryId.isEmpty) return;
                final svc = ref.read(inventoryServiceProvider);
                if (item == null) {
                  await svc.createItem(
                    name: nameCtrl.text,
                    categoryId: categoryId,
                    supplierId: supplierId,
                    unit: unit,
                    costPrice: cost,
                    sellingPrice: sell,
                    quantity: qty.toInt(),
                    minThreshold: minT.toInt(),
                    location: locCtrl.text.isEmpty ? null : locCtrl.text,
                  );
                  if (supplierId != null && qty > 0 && context.mounted) {
                    Navigator.pop(ctx);
                    await showPaymentSettleSheet(
                      context,
                      supplierId: supplierId!,
                      supplierName: suppliers.firstWhere((s) => s.id == supplierId).name,
                      goodsCost: qty * cost,
                      settleContext: 'stock_in',
                      referenceLabel: 'New item ${nameCtrl.text}',
                    );
                  }
                } else {
                  await svc.updateItem(
                    id: item.id,
                    name: nameCtrl.text,
                    categoryId: categoryId,
                    supplierId: supplierId,
                    unit: unit,
                    costPrice: cost,
                    sellingPrice: sell,
                    minThreshold: minT.toInt(),
                    location: locCtrl.text.isEmpty ? null : locCtrl.text,
                  );
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: Text(item == null ? 'Add Item' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRestock(BuildContext context, Item item, List<Supplier> suppliers) async {
    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a supplier first')));
      return;
    }
    var qty = 1.0;
    var cost = item.costPrice;
    var sell = item.sellingPrice;
    var supplierId = item.supplierId ?? suppliers.first.id;

    await showApexModal(
      context: context,
      title: 'Restock ${item.name}',
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          children: [
            NumberField(label: 'Quantity', value: qty, integer: true, onChanged: (v) => qty = v),
            NumberField(label: 'Unit cost', value: cost, onChanged: (v) => cost = v),
            NumberField(label: 'Selling price', value: sell, onChanged: (v) => sell = v),
            DropdownButtonFormField<String>(
              value: supplierId,
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (v) => setModal(() => supplierId = v ?? supplierId),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref.read(inventoryServiceProvider).restock(
                      itemId: item.id,
                      quantity: qty.toInt(),
                      unitCost: cost,
                      sellingPrice: sell,
                      supplierId: supplierId,
                    );
                if (context.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  await showPaymentSettleSheet(
                    context,
                    supplierId: supplierId,
                    supplierName: suppliers.firstWhere((s) => s.id == supplierId).name,
                    goodsCost: qty * cost,
                    settleContext: 'stock_in',
                    referenceLabel: 'Restock ${item.name}',
                  );
                }
              },
              child: const Text('Restock & Update Stock'),
            ),
          ],
        ),
      ),
    );
  }
}
