import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/database/enums.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/services_provider.dart';
import '../../core/services/sales_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';
import '../../shared/widgets/number_field.dart';
import 'services/receipt_pdf_service.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesStreamProvider);
    final items = ref.watch(itemsStreamProvider).value ?? [];

    return Scaffold(
      body: salesAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => Center(child: Text('$e')),
        data: (sales) {
          final totalRevenue = sales.fold(0.0, (s, r) => s + r.totalAmount);
          final totalProfit = sales.fold(0.0, (s, r) => s + r.profit);

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
                        Text('Sales & Commission', style: Theme.of(context).textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: () => _openSaleForm(context, items),
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: const Text('Record Sale'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ApexCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Revenue', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                GhcText(totalRevenue, bold: true),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ApexCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Profit', style: TextStyle(fontSize: 11, color: AppColors.success)),
                                GhcText(totalProfit, bold: true, color: AppColors.success),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sales.isEmpty
                    ? const Center(child: Text('No sales recorded yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sales.length,
                        itemBuilder: (_, idx) => _SaleTile(sale: sales[idx], items: items),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSaleForm(BuildContext context, List<Item> items) async {
    final customerCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var date = DateTime.now();
    final lines = <_SaleLine>[ _SaleLine() ];
    var discountType = DiscountType.none;
    var moneyDiscount = 0.0;
    String? freeItemId;
    var freeQty = 1.0;

    await showApexModal(
      context: context,
      title: 'Record Sale',
      subtitle: 'Add multiple items to one transaction',
      child: StatefulBuilder(
        builder: (ctx, setModal) {
          var subtotal = 0.0;
          for (final line in lines) {
            if (line.itemId != null) subtotal += line.qty * line.price;
          }
          final appliedDiscount =
              discountType == DiscountType.money ? moneyDiscount.clamp(0, subtotal) : 0.0;
          final grandTotal = (subtotal - appliedDiscount).clamp(0, double.infinity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: customerCtrl,
                decoration: const InputDecoration(labelText: 'Customer / Project reference'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Transaction date'),
                subtitle: Text('${date.day}/${date.month}/${date.year}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setModal(() => date = picked);
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sale Items', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => setModal(() => lines.add(_SaleLine())),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              ...lines.asMap().entries.map((e) {
                final idx = e.key;
                final line = e.value;
                final item = line.itemId != null
                    ? items.cast<Item?>().firstWhere((i) => i?.id == line.itemId, orElse: () => null)
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ApexCard(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: line.itemId,
                          decoration: const InputDecoration(labelText: 'Item'),
                          items: items
                              .map((i) => DropdownMenuItem(
                                    value: i.id,
                                    child: Text('${i.name} (${i.quantity} ${i.unit})'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setModal(() {
                              line.itemId = v;
                              final sel = items.firstWhere((i) => i.id == v);
                              line.price = sel.sellingPrice;
                              line.cost = sel.costPrice;
                            });
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: NumberField(
                                label: 'Qty',
                                value: line.qty,
                                integer: true,
                                min: 1,
                                onChanged: (v) => setModal(() => line.qty = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: NumberField(
                                label: 'Sell price',
                                value: line.price,
                                onChanged: (v) => setModal(() => line.price = v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.danger),
                              onPressed: lines.length > 1
                                  ? () => setModal(() => lines.removeAt(idx))
                                  : null,
                            ),
                          ],
                        ),
                        if (item != null && line.qty > item.quantity)
                          Text('Only ${item.quantity} ${item.unit} in stock',
                              style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }),
              const Text('Discount', style: TextStyle(fontWeight: FontWeight.bold)),
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(value: DiscountType.none, label: Text('None')),
                  ButtonSegment(value: DiscountType.money, label: Text('Money off')),
                  ButtonSegment(value: DiscountType.freeItem, label: Text('Free item')),
                ],
                selected: {discountType},
                onSelectionChanged: (s) => setModal(() => discountType = s.first),
              ),
              if (discountType == DiscountType.money)
                NumberField(
                  label: 'Discount amount',
                  value: moneyDiscount,
                  onChanged: (v) => setModal(() => moneyDiscount = v),
                ),
              if (discountType == DiscountType.freeItem) ...[
                DropdownButtonFormField<String>(
                  initialValue: freeItemId,
                  decoration: const InputDecoration(labelText: 'Free item'),
                  items: items
                      .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
                      .toList(),
                  onChanged: (v) => setModal(() => freeItemId = v),
                ),
                NumberField(
                  label: 'Free qty',
                  value: freeQty,
                  integer: true,
                  onChanged: (v) => setModal(() => freeQty = v),
                ),
              ],
              ApexCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total sale amount'),
                        Text(CurrencyFormatter.format(grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    final result = await ref.read(salesServiceProvider).recordSale(
                          lines: lines
                              .where((l) => l.itemId != null && l.qty > 0)
                              .map((l) => SaleLineInput(
                                    itemId: l.itemId!,
                                    quantity: l.qty.toInt(),
                                    sellingPrice: l.price,
                                    costPrice: l.cost,
                                  ))
                              .toList(),
                          dispatchedAt: date,
                          customerReference:
                              customerCtrl.text.isEmpty ? null : customerCtrl.text,
                          notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                          discount: DiscountInput(
                            type: discountType,
                            moneyAmount: moneyDiscount,
                            freeItemId: freeItemId,
                            freeQuantity: freeQty.toInt(),
                          ),
                        );
                    if (context.mounted) Navigator.pop(ctx);
                    if (context.mounted) _showPostSaleSheet(context, result, customerCtrl.text, date, discountType, moneyDiscount);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                child: const Text('Record Sale'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPostSaleSheet(
    BuildContext context,
    SaleResult result,
    String customer,
    DateTime date,
    DiscountType discountType,
    double moneyDiscount,
  ) {
    final shopName = ref.read(shopNameProvider).value ?? 'Apex Building Accessories';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            const Text('Sale recorded successfully', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Receipt ${result.saleReference}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final receipt = ReceiptData(
                  receiptNo: result.saleReference,
                  customerName: customer.isEmpty ? 'Walk-in customer' : customer,
                  dispatchedAt: date,
                  shopName: shopName,
                  items: result.lines
                      .map((l) => ReceiptLine(
                            name: l.itemName,
                            quantity: l.quantity,
                            unit: l.unit,
                            sellingPrice: l.sellingPrice,
                          ))
                      .toList(),
                  totalAmount: result.totalAmount,
                  subtotal: discountType == DiscountType.money ? result.totalAmount + moneyDiscount : null,
                  discountNote: discountType == DiscountType.money
                      ? 'Discount: -${CurrencyFormatter.formatPdf(moneyDiscount)}'
                      : discountType == DiscountType.freeItem
                          ? 'Includes free item'
                          : null,
                );
                await ReceiptPdfService.shareReceipt(receipt);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share via WhatsApp'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final receipt = ReceiptData(
                  receiptNo: result.saleReference,
                  customerName: customer.isEmpty ? 'Walk-in customer' : customer,
                  dispatchedAt: date,
                  shopName: shopName,
                  items: result.lines
                      .map((l) => ReceiptLine(
                            name: l.itemName,
                            quantity: l.quantity,
                            unit: l.unit,
                            sellingPrice: l.sellingPrice,
                          ))
                      .toList(),
                  totalAmount: result.totalAmount,
                );
                await ReceiptPdfService.printReceipt(receipt);
              },
              icon: const Icon(Icons.print),
              label: const Text('Print receipt'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      ),
    );
  }
}

class _SaleLine {
  String? itemId;
  double qty = 1;
  double price = 0;
  double cost = 0;
}

class _SaleTile extends ConsumerWidget {
  const _SaleTile({required this.sale, required this.items});

  final StockOut sale;
  final List<Item> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = items.cast<Item?>().firstWhere((i) => i?.id == sale.itemId, orElse: () => null);
    final name = item?.name ?? 'Item';

    return ApexCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${sale.dispatchedAt.day}/${sale.dispatchedAt.month}/${sale.dispatchedAt.year} · ${sale.quantity} ${item?.unit ?? 'pcs'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (sale.saleReference != null)
                  Text(sale.saleReference!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GhcText(sale.totalAmount, bold: true),
              Text('+${CurrencyFormatter.format(sale.profit)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontFamily: 'monospace')),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 18),
            onPressed: () async {
              if (sale.saleReference == null) return;
              final group = await ref.read(salesServiceProvider).getSalesByReference(sale.saleReference!);
              final shopName = ref.read(shopNameProvider).value ?? 'Apex Building Accessories';
              final receipt = ReceiptData(
                receiptNo: sale.saleReference!,
                customerName: sale.customerReference ?? 'Walk-in customer',
                dispatchedAt: sale.dispatchedAt,
                shopName: shopName,
                items: group.map((s) {
                  final it = items.cast<Item?>().firstWhere((i) => i?.id == s.itemId, orElse: () => null);
                  return ReceiptLine(
                    name: it?.name ?? 'Item',
                    quantity: s.quantity,
                    unit: it?.unit ?? 'pcs',
                    sellingPrice: s.sellingPrice,
                  );
                }).toList(),
                totalAmount: group.fold(0.0, (a, b) => a + b.totalAmount),
              );
              await ReceiptPdfService.shareReceipt(receipt);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
            onPressed: () async {
              await ref.read(salesServiceProvider).deleteSale(sale.id);
            },
          ),
        ],
      ),
    );
  }
}
