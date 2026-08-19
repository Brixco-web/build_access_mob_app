import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/services_provider.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';
import '../../shared/widgets/number_field.dart';

final financialProvider = FutureProvider.family<dynamic, (int, int)>((ref, params) async {
  return ref.watch(financialServiceProvider).getSummary(params.$1, params.$2);
});

class FinancialScreen extends ConsumerStatefulWidget {
  const FinancialScreen({super.key});

  @override
  ConsumerState<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends ConsumerState<FinancialScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final finAsync = ref.watch(financialProvider((_year, _month)));

    return finAsync.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(child: Text('$e')),
      data: (data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Financial Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _month,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                  ),
                  onChanged: (v) => setState(() => _month = v ?? _month),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _year,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: [2024, 2025, 2026, 2027]
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _card('Revenue', data.totalRevenue, AppColors.warning),
              _card('Commission', data.totalCommission, AppColors.success),
              _card('Stock Received', data.totalStockReceived, AppColors.accent),
              _card('Other Expenses', data.totalOtherExpenses, const Color(0xFF7C3AED)),
              _card('Inventory Value', data.inventoryValue, AppColors.primary),
              _card('Outstanding Debt', data.totalOutstandingDebt, AppColors.danger),
            ],
          ),
          const SizedBox(height: 16),
          ApexCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Cash Flow', style: TextStyle(fontWeight: FontWeight.bold)),
                    GhcText(data.netCashFlow,
                        bold: true,
                        color: data.netCashFlow >= 0 ? AppColors.success : AppColors.danger),
                  ],
                ),
                Text('Gross margin: ${data.grossMarginPct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Pending orders: ${data.pendingOrderCount} (GH₵ ${data.pendingOrderValue.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (data.suppliersWithDebt.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Supplier Debt', style: TextStyle(fontWeight: FontWeight.bold)),
            ...data.suppliersWithDebt.map(
              (s) => ListTile(
                title: Text(s.name),
                trailing: GhcText(s.amountOwed, color: AppColors.danger),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Other Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _addExpense(context),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          ...data.otherExpenses.map(
            (e) => ListTile(
              title: Text(e.label),
              subtitle: Text('${e.expenseDate.day}/${e.expenseDate.month}/${e.expenseDate.year}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GhcText(e.amount),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    onPressed: () => ref.read(financialServiceProvider).deleteExpense(e.id, e.label),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String label, double amount, Color color) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const Spacer(),
          GhcText(amount, bold: true),
        ],
      ),
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    final labelCtrl = TextEditingController();
    var amount = 0.0;
    await showApexModal(
      context: context,
      title: 'Add Expense',
      child: Column(
        children: [
          TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
          NumberField(label: 'Amount', value: amount, onChanged: (v) => amount = v),
          FilledButton(
            onPressed: () async {
              await ref.read(financialServiceProvider).addExpense(label: labelCtrl.text, amount: amount);
              if (context.mounted) Navigator.pop(context);
              ref.invalidate(financialProvider((_year, _month)));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
