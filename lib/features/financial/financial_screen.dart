import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/services_provider.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../../shared/widgets/apex_modal.dart';
import '../../shared/widgets/number_field.dart';
import 'report_modal.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Financial Overview', style: Theme.of(context).textTheme.titleLarge),
                    Text('${_monthNames[_month - 1]} $_year',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => ReportModal.show(context, initialMonth: _month, initialYear: _year),
                icon: const Icon(LucideIcons.download, size: 16),
                label: const Text('Report'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(value: i + 1, child: Text(_monthNames[i])),
                  ),
                  onChanged: (v) => setState(() => _month = v ?? _month),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
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
            childAspectRatio: 1.45,
            children: [
              _metricCard('Total Revenue', data.totalRevenue, LucideIcons.shoppingCart, AppColors.accent),
              _metricCard('Commission / Profit', data.totalCommission, LucideIcons.trendingUp, AppColors.success),
              _metricCard('Stock Received', data.totalStockReceived, LucideIcons.package, AppColors.warning),
              _metricCard('Other Expenses', data.totalOtherExpenses, LucideIcons.receipt, const Color(0xFF7C3AED)),
              _metricCard('Inventory Value', data.inventoryValue, LucideIcons.dollarSign, AppColors.primary),
              _metricCard(
                'Pending Orders',
                data.pendingOrderValue,
                LucideIcons.clock,
                const Color(0xFFEA580C),
                subtitle: '${data.pendingOrderCount} orders',
                isCurrency: true,
              ),
              _metricCard('Outstanding Debt', data.totalOutstandingDebt, LucideIcons.wallet, AppColors.danger),
              _metricCard(
                'Gross Margin',
                data.grossMarginPct,
                LucideIcons.percent,
                const Color(0xFF0D9488),
                isCurrency: false,
              ),
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
                const SizedBox(height: 4),
                Text(
                  'Revenue − stock received − other expenses for ${_monthNames[_month - 1]} $_year',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (data.suppliersWithDebt.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Supplier Debt Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
            ...data.suppliersWithDebt.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.name),
                trailing: GhcText(s.amountOwed, color: AppColors.danger),
                onTap: () => context.go('/suppliers/${s.id}'),
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
          if (data.otherExpenses.isEmpty)
            const Text('No expenses recorded this month.', style: TextStyle(color: AppColors.textSecondary))
          else
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
                      onPressed: () async {
                        await ref.read(financialServiceProvider).deleteExpense(e.id, e.label);
                        ref.invalidate(financialProvider((_year, _month)));
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String label,
    double value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isCurrency = true,
  }) {
    return ApexCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Spacer(),
          if (isCurrency)
            GhcText(value, bold: true)
          else
            Text(
              '${value.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          if (isCurrency && subtitle != null)
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
