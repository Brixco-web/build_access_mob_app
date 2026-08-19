import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/enums.dart';
import '../../core/providers/services_provider.dart';
import '../../core/services/order_service.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';
import '../../shared/widgets/number_field.dart';
import '../../shared/widgets/payment_settle_sheet.dart';
import '../../shared/widgets/status_badge.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final items = ref.watch(itemsStreamProvider).value ?? [];
    final suppliers = ref.watch(suppliersProvider).value ?? [];

    return Scaffold(
      body: ordersAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('$e')),
        data: (orders) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Orders', style: Theme.of(context).textTheme.titleLarge),
                  FilledButton.icon(
                    onPressed: () => _placeOrder(context, ref, items, suppliers),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Place Order'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('No orders yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      itemBuilder: (_, i) {
                        final o = orders[i];
                        final status = orderStatusFromDb(o.order.status);
                        return ApexCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(o.order.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  StatusBadge.order(status),
                                ],
                              ),
                              Text(o.supplierName, style: const TextStyle(color: AppColors.textSecondary)),
                              Text('${o.items.length} items · GH₵ ${o.order.totalCost.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (status != OrderStatus.cancelled && status != OrderStatus.received)
                                    TextButton.icon(
                                      onPressed: () => _receiveOrder(context, ref, o),
                                      icon: const Icon(LucideIcons.packageCheck, size: 16),
                                      label: const Text('Receive'),
                                    ),
                                  if (status == OrderStatus.pending)
                                    TextButton.icon(
                                      onPressed: () => ref
                                          .read(orderServiceProvider)
                                          .cancelOrder(o.order.id, o.order.orderNumber),
                                      icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                                      label: const Text('Cancel'),
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
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> items,
    List<dynamic> suppliers,
  ) async {
    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a supplier first')));
      return;
    }
    final orderNumCtrl = TextEditingController(text: 'ORD-${DateTime.now().millisecondsSinceEpoch}');
    var supplierId = suppliers.first.id as String;
    final lines = [_OrderLine()];

    await showApexModal(
      context: context,
      title: 'Place New Order',
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          children: [
            TextField(controller: orderNumCtrl, decoration: const InputDecoration(labelText: 'Order number')),
            DropdownButtonFormField<String>(
              value: supplierId,
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: suppliers
                  .map((s) => DropdownMenuItem(value: s.id as String, child: Text(s.name as String)))
                  .toList(),
              onChanged: (v) => setModal(() => supplierId = v ?? supplierId),
            ),
            ...lines.asMap().entries.map((e) {
              final idx = e.key;
              final line = e.value;
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: line.itemId,
                      decoration: const InputDecoration(labelText: 'Item'),
                      items: items
                          .map((i) => DropdownMenuItem(value: i.id as String, child: Text(i.name as String)))
                          .toList(),
                      onChanged: (v) => setModal(() {
                        line.itemId = v;
                        final sel = items.firstWhere((i) => i.id == v);
                        line.unitCost = sel.costPrice as double;
                      }),
                    ),
                  ),
                  Expanded(
                    child: NumberField(
                      label: 'Qty',
                      value: line.qty,
                      integer: true,
                      onChanged: (v) => setModal(() => line.qty = v),
                    ),
                  ),
                  Expanded(
                    child: NumberField(
                      label: 'Cost',
                      value: line.unitCost,
                      onChanged: (v) => setModal(() => line.unitCost = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: lines.length > 1 ? () => setModal(() => lines.removeAt(idx)) : null,
                  ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: () => setModal(() => lines.add(_OrderLine())),
              icon: const Icon(Icons.add),
              label: const Text('Add line'),
            ),
            FilledButton(
              onPressed: () async {
                final order = await ref.read(orderServiceProvider).placeOrder(
                      orderNumber: orderNumCtrl.text,
                      supplierId: supplierId,
                      lines: lines
                          .where((l) => l.itemId != null)
                          .map((l) => OrderLineInput(
                                itemId: l.itemId!,
                                quantity: l.qty.toInt(),
                                unitCost: l.unitCost,
                              ))
                          .toList(),
                    );
                if (context.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  await showPaymentSettleSheet(
                    context,
                    supplierId: supplierId,
                    supplierName: suppliers.firstWhere((s) => s.id == supplierId).name as String,
                    goodsCost: order.order.totalCost,
                    settleContext: 'order',
                    referenceLabel: 'Order ${order.order.orderNumber}',
                  );
                  ref.invalidate(ordersProvider);
                }
              },
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _receiveOrder(BuildContext context, WidgetRef ref, OrderWithItems order) async {
    final refCtrl = TextEditingController(text: 'RCV-${order.order.orderNumber}');
    final receiveLines = order.items
        .where((i) => i.line.quantityOrdered > i.line.quantityReceived)
        .map((i) => _ReceiveLine(
              itemId: i.line.itemId,
              name: i.itemName,
              max: i.line.quantityOrdered - i.line.quantityReceived,
              unit: i.unit,
              qty: (i.line.quantityOrdered - i.line.quantityReceived).toDouble(),
              sellingPrice: 0,
            ))
        .toList();

    await showApexModal(
      context: context,
      title: 'Receive ${order.order.orderNumber}',
      child: StatefulBuilder(
        builder: (ctx, setModal) => Column(
          children: [
            TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Receipt ref')),
            ...receiveLines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ApexCard(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Remaining: ${line.max} ${line.unit}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      NumberField(
                        label: 'Qty to receive',
                        value: line.qty,
                        integer: true,
                        max: line.max.toDouble(),
                        onChanged: (v) => setModal(() => line.qty = v),
                      ),
                      NumberField(
                        label: 'Selling price',
                        value: line.sellingPrice,
                        onChanged: (v) => setModal(() => line.sellingPrice = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                final items = ref.read(itemsStreamProvider).value ?? [];
                for (final line in receiveLines) {
                  if (line.sellingPrice == 0) {
                    final matches = items.where((i) => i.id == line.itemId);
                    if (matches.isNotEmpty) line.sellingPrice = matches.first.sellingPrice;
                  }
                }
                final cost = await ref.read(orderServiceProvider).receiveOrder(
                      orderId: order.order.id,
                      referenceNumber: refCtrl.text,
                      lines: receiveLines
                          .where((l) => l.qty > 0)
                          .map((l) => ReceiveLineInput(
                                itemId: l.itemId,
                                quantity: l.qty.toInt(),
                                sellingPrice: l.sellingPrice,
                              ))
                          .toList(),
                    );
                if (context.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  await showPaymentSettleSheet(
                    context,
                    supplierId: order.order.supplierId,
                    supplierName: order.supplierName,
                    goodsCost: cost,
                    settleContext: 'stock_in',
                    referenceLabel: 'Received ${refCtrl.text}',
                  );
                  ref.invalidate(ordersProvider);
                }
              },
              child: const Text('Receive & Update Stock'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderLine {
  String? itemId;
  double qty = 1;
  double unitCost = 0;
}

class _ReceiveLine {
  _ReceiveLine({
    required this.itemId,
    required this.name,
    required this.max,
    required this.unit,
    required this.qty,
    required this.sellingPrice,
  });

  final String itemId;
  final String name;
  final int max;
  final String unit;
  double qty;
  double sellingPrice;
}
