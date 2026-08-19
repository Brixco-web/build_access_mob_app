import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/services_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/widgets/apex_card.dart';
import '../../shared/widgets/loading_shimmer.dart';

final reportProvider = FutureProvider.family<dynamic, (int, int)>((ref, p) {
  return ref.watch(financialServiceProvider).getMonthlyReport(p.$1, p.$2);
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider((_year, _month)));

    return reportAsync.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(child: Text('$e')),
      data: (report) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Monthly Reports', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _month,
                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Month ${i + 1}'))),
                  onChanged: (v) => setState(() => _month = v ?? _month),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _year,
                  items: [2024, 2025, 2026, 2027]
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v ?? _year),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ApexCard(
            child: Column(
              children: [
                _row('Stock In Value', report.totalStockReceivedValue),
                _row('Sales Value', report.totalSalesValue),
                _row('Net Change', report.netInventoryChange),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _exportPdf(report),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export PDF'),
          ),
          const SizedBox(height: 16),
          ...report.breakdown.map(
            (row) => ListTile(
              title: Text(row.itemName),
              subtitle: Text('In: ${row.stockInQty} ${row.unit} · Sold: ${row.soldQty}'),
              trailing: Text(CurrencyFormatter.format(row.salesValue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(CurrencyFormatter.format(v), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Future<void> _exportPdf(report) async {
    final shopName = ref.read(shopNameProvider).value ?? 'Apex Building Accessories';
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Monthly Report — $_month/$_year'),
            pw.SizedBox(height: 12),
            pw.Text('Stock In: ${CurrencyFormatter.formatPdf(report.totalStockReceivedValue)}'),
            pw.Text('Sales: ${CurrencyFormatter.formatPdf(report.totalSalesValue)}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Stock In', 'Sold', 'Sales Value'],
              data: report.breakdown
                  .map((r) => [
                        r.itemName,
                        '${r.stockInQty}',
                        '${r.soldQty}',
                        CurrencyFormatter.formatPdf(r.salesValue),
                      ])
                  .toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
