import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/services_provider.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';
import '../../shared/widgets/number_field.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      body: suppliersAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('$e')),
        data: (suppliers) {
          final debtRows = ref.watch(supplierServiceProvider);
          return FutureBuilder(
            future: debtRows.getSuppliersWithDebt(),
            builder: (context, debtSnap) {
              final debtMap = {
                for (final d in debtSnap.data ?? []) d.id: d.amountOwed,
              };

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Suppliers', style: Theme.of(context).textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: () => _addSupplier(context, ref),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: suppliers.length,
                      itemBuilder: (_, i) {
                        final s = suppliers[i];
                        final owed = debtMap[s.id] ?? s.balanceOwed;
                        return ApexCard(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: owed > 0
                                ? Text('Owes GH₵ ${owed.toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppColors.danger))
                                : const Text('No outstanding debt'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/suppliers/${s.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addSupplier(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    await showApexModal(
      context: context,
      title: 'Add Supplier',
      child: Column(
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact person')),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          FilledButton(
            onPressed: () async {
              await ref.read(supplierServiceProvider).createSupplier(
                    name: nameCtrl.text,
                    contactPerson: contactCtrl.text.isEmpty ? null : contactCtrl.text,
                    phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                  );
              ref.invalidate(suppliersProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(supplierServiceProvider).getSupplierDetail(id),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final detail = snap.data!;
        final s = detail.supplier;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.name, style: Theme.of(context).textTheme.titleLarge),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.pencil, size: 18),
                  onPressed: () => _editSupplier(context, ref, s),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                  onPressed: () => _deleteSupplier(context, ref, s),
                ),
              ],
            ),
            if (s.contactPerson != null) Text(s.contactPerson!),
            if (s.phone != null) Text(s.phone!),
            const SizedBox(height: 12),
            ApexCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount owed', style: TextStyle(fontWeight: FontWeight.bold)),
                  GhcText(detail.amountOwed, bold: true, color: AppColors.danger),
                ],
              ),
            ),
            if (detail.amountOwed > 0) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _payDebt(context, ref, s.id, s.name, detail.amountOwed),
                icon: const Icon(LucideIcons.wallet),
                label: const Text('Pay Debt'),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Recent Stock-In', style: TextStyle(fontWeight: FontWeight.bold)),
            ...detail.stockIns.take(5).map(
                  (si) => ListTile(
                    title: Text(si.referenceNumber),
                    subtitle: Text('${si.receivedDate.day}/${si.receivedDate.month}/${si.receivedDate.year}'),
                    trailing: GhcText(si.totalCost),
                  ),
                ),
            const SizedBox(height: 16),
            const Text('Orders', style: TextStyle(fontWeight: FontWeight.bold)),
            ...detail.orders.map(
              (o) => ListTile(
                title: Text(o.order.orderNumber),
                subtitle: Text(o.supplierName),
                trailing: GhcText(o.order.totalCost),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _payDebt(BuildContext context, WidgetRef ref, String id, String name, double owed) async {
    var amount = owed;
    final notesCtrl = TextEditingController();
    await showApexModal(
      context: context,
      title: 'Pay $name',
      child: Column(
        children: [
          NumberField(label: 'Amount', value: amount, onChanged: (v) => amount = v),
          TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
          FilledButton(
            onPressed: () async {
              await ref.read(supplierServiceProvider).payDebt(
                    supplierId: id,
                    amount: amount,
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _editSupplier(BuildContext context, WidgetRef ref, Supplier s) async {
    final nameCtrl = TextEditingController(text: s.name);
    final contactCtrl = TextEditingController(text: s.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: s.phone ?? '');
    await showApexModal(
      context: context,
      title: 'Edit Supplier',
      child: Column(
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact person')),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          FilledButton(
            onPressed: () async {
              await ref.read(supplierServiceProvider).updateSupplier(
                    id: s.id,
                    name: nameCtrl.text.trim(),
                    contactPerson: contactCtrl.text.isEmpty ? null : contactCtrl.text,
                    phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                  );
              ref.invalidate(suppliersProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(BuildContext context, WidgetRef ref, Supplier s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete supplier?'),
        content: Text('Remove ${s.name} from your local records?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(supplierServiceProvider).deleteSupplier(s.id, s.name);
    ref.invalidate(suppliersProvider);
    if (context.mounted) context.go('/suppliers');
  }
}
