import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/services_provider.dart';
import '../../core/services/financial_service.dart';
import '../../shared/widgets/apex_card.dart';
import 'services/report_pdf_service.dart';

enum ReportPeriodType {
  thisMonth,
  lastMonth,
  ytd,
  allTime,
  customMonth,
  customRange,
}

class ReportModal extends ConsumerStatefulWidget {
  const ReportModal({
    super.key,
    required this.initialMonth,
    required this.initialYear,
  });

  final int initialMonth;
  final int initialYear;

  static Future<void> show(
    BuildContext context, {
    required int initialMonth,
    required int initialYear,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ReportModal(initialMonth: initialMonth, initialYear: initialYear),
      ),
    );
  }

  @override
  ConsumerState<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends ConsumerState<ReportModal> {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  ReportPeriodType _periodType = ReportPeriodType.thisMonth;
  ReportScope _scope = ReportScope.full;
  late int _month;
  late int _year;
  late DateTime _startDate;
  late DateTime _endDate;
  CustomReport? _report;
  bool _loading = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
    _year = widget.initialYear;
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final financial = ref.read(financialServiceProvider);
      final now = DateTime.now();
      CustomReport report;

      switch (_periodType) {
        case ReportPeriodType.thisMonth:
          report = await financial.getCustomReport(month: now.month, year: now.year);
        case ReportPeriodType.lastMonth:
          final last = DateTime(now.year, now.month - 1, 1);
          report = await financial.getCustomReport(month: last.month, year: last.year);
        case ReportPeriodType.ytd:
          report = await financial.getCustomReport(
            startDate: DateTime(now.year, 1, 1),
            endDate: now,
          );
        case ReportPeriodType.allTime:
          report = await financial.getCustomReport(allTime: true);
        case ReportPeriodType.customMonth:
          report = await financial.getCustomReport(month: _month, year: _year);
        case ReportPeriodType.customRange:
          report = await financial.getCustomReport(startDate: _startDate, endDate: _endDate);
      }

      if (mounted) setState(() => _report = report);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePdf() async {
    final report = _report;
    if (report == null) return;
    setState(() => _generating = true);
    try {
      final shopName = ref.read(shopNameProvider).value ?? 'Apex Building Accessories';
      await ReportPdfService.printReport(shopName: shopName, report: report, scope: _scope);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Generate Business Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Select period and scope to export PDF',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('1. Select Time Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _periodChip('This Month', ReportPeriodType.thisMonth),
                  _periodChip('Last Month', ReportPeriodType.lastMonth),
                  _periodChip('Year to Date', ReportPeriodType.ytd),
                  _periodChip('All-Time', ReportPeriodType.allTime),
                  _periodChip('Select Month', ReportPeriodType.customMonth),
                  _periodChip('Custom Dates', ReportPeriodType.customRange),
                ],
              ),
              if (_periodType == ReportPeriodType.customMonth) ...[
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
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _month = v);
                          _loadReport();
                        },
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
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _year = v);
                          _loadReport();
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (_periodType == ReportPeriodType.customRange) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                            _loadReport();
                          }
                        },
                        child: Text('From ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                            _loadReport();
                          }
                        },
                        child: Text('To ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              const Text('2. Report Type & Scope', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              _scopeTile('Full Business Audit', 'Financials, inventory breakdown, & debts', ReportScope.full),
              _scopeTile('Executive Summary', '1-page financial overview', ReportScope.executive),
              _scopeTile('Stock & Dispatches', 'Item-level stock-in & sales movement', ReportScope.inventory),
              const SizedBox(height: 20),
              ApexCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Report Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (_report != null)
                          Text(_report!.periodLabel,
                              style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const LinearProgressIndicator()
                    else if (_report == null)
                      const Text('No data available for this range.')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _previewChip('Sales Revenue', _report!.totalRevenue),
                          _previewChip('Commission', _report!.totalCommission, color: AppColors.success),
                          _previewChip('Stock Received', _report!.totalStockReceived, color: AppColors.warning),
                          _previewChip('Net Cash Flow', _report!.netCashFlow,
                              color: _report!.netCashFlow >= 0 ? AppColors.success : AppColors.danger),
                          _previewChip('Supplier Debt', _report!.totalOutstandingDebt, color: AppColors.danger),
                          _previewChip('Items Traded', _report!.breakdown.length.toDouble(), isCount: true),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _report == null || _loading || _generating ? null : _generatePdf,
                icon: _generating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                label: Text(_generating ? 'Generating PDF...' : 'Download PDF Report'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _periodChip(String label, ReportPeriodType type) {
    final selected = _periodType == type;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _periodType = type);
        _loadReport();
      },
      selectedColor: AppColors.accentBg,
      checkmarkColor: AppColors.accent,
    );
  }

  Widget _scopeTile(String title, String subtitle, ReportScope scope) {
    final selected = _scope == scope;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.accent : AppColors.border, width: selected ? 2 : 1),
        ),
        tileColor: selected ? AppColors.accentBg : Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        onTap: () => setState(() => _scope = scope),
      ),
    );
  }

  Widget _previewChip(String label, double value, {Color? color, bool isCount = false}) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 72) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            isCount ? value.toInt().toString() : 'GH₵ ${value.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
