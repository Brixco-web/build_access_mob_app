import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/services_provider.dart';
import '../../core/services/supplier_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../widgets/apex_card.dart';
import '../widgets/number_field.dart';

class PaymentSettleSheet extends ConsumerStatefulWidget {
  const PaymentSettleSheet({
    super.key,
    required this.supplierId,
    required this.supplierName,
    required this.goodsCost,
    required this.context,
    required this.referenceLabel,
    this.onComplete,
  });

  final String supplierId;
  final String supplierName;
  final double goodsCost;
  final String context;
  final String referenceLabel;
  final VoidCallback? onComplete;

  @override
  ConsumerState<PaymentSettleSheet> createState() => _PaymentSettleSheetState();
}

class _PaymentSettleSheetState extends ConsumerState<PaymentSettleSheet> {
  final _expenses = <_ExpenseLine>[];
  double _amountPaid = 0;
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountPaid = widget.goodsCost;
  }

  double get _expenseTotal => _expenses.fold(0.0, (s, e) => s + e.amount);
  double get _totalOwed => widget.goodsCost + _expenseTotal;
  double get _debtAdded => (_totalOwed - _amountPaid).clamp(0, double.infinity);

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(supplierServiceProvider).settle(
            supplierId: widget.supplierId,
            goodsCost: widget.goodsCost,
            amountPaid: _amountPaid,
            expenses: _expenses
                .where((e) => e.amount > 0)
                .map((e) => ExpenseLineInput(label: e.label, amount: e.amount))
                .toList(),
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            context: widget.context,
            referenceLabel: widget.referenceLabel,
          );
      if (mounted) {
        widget.onComplete?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Payment — ${widget.supplierName}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(widget.referenceLabel,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ApexCard(
            child: Column(
              children: [
                _row('Goods cost', widget.goodsCost),
                _row('Other expenses', _expenseTotal),
                const Divider(),
                _row('Total owed', _totalOwed, bold: true),
                _row('Debt added', _debtAdded, color: AppColors.danger),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._expenses.asMap().entries.map((e) {
            final idx = e.key;
            final exp = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Expense label'),
                      onChanged: (v) => exp.label = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: NumberField(
                      value: exp.amount,
                      onChanged: (v) => setState(() => exp.amount = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: () => setState(() => _expenses.removeAt(idx)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _expenses.add(_ExpenseLine())),
            icon: const Icon(Icons.add),
            label: const Text('Add expense line'),
          ),
          NumberField(
            label: 'Amount paid (GH₵)',
            value: _amountPaid,
            onChanged: (v) => setState(() => _amountPaid = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseLine {
  String label = '';
  double amount = 0;
}

Future<bool?> showPaymentSettleSheet(
  BuildContext context, {
  required String supplierId,
  required String supplierName,
  required double goodsCost,
  required String settleContext,
  required String referenceLabel,
  VoidCallback? onComplete,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: PaymentSettleSheet(
        supplierId: supplierId,
        supplierName: supplierName,
        goodsCost: goodsCost,
        context: settleContext,
        referenceLabel: referenceLabel,
        onComplete: onComplete,
      ),
    ),
  );
}
