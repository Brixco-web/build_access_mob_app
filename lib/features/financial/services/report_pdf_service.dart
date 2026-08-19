import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/financial_service.dart';
import '../../../core/utils/currency_formatter.dart';

enum ReportScope { full, executive, inventory }

class ReportPdfService {
  static Future<void> printReport({
    required String shopName,
    required CustomReport report,
    required ReportScope scope,
  }) async {
    final pdf = _buildDocument(shopName: shopName, report: report, scope: scope);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static pw.Document _buildDocument({
    required String shopName,
    required CustomReport report,
    required ReportScope scope,
  }) {
    final doc = pw.Document();
    final generated = DateTime.now();
    final scopeLabel = switch (scope) {
      ReportScope.full => 'Comprehensive Business & Financial Statement',
      ReportScope.executive => 'Executive Financial Summary',
      ReportScope.inventory => 'Inventory & Dispatches Audit Statement',
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(shopName.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(scopeLabel, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Report Period: ${report.periodLabel}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              'Date Generated: ${generated.day.toString().padLeft(2, '0')} ${_monthShort(generated.month)} ${generated.year}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Divider(),
          ];

          if (scope == ReportScope.full || scope == ReportScope.executive) {
            widgets.addAll([
              pw.Text('Financial Summary Snapshot', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Financial Metric', 'Amount (GH₵)'],
                data: [
                  ['Total Sales Revenue', CurrencyFormatter.formatPdf(report.totalRevenue)],
                  ['Gross Profit / Commission', CurrencyFormatter.formatPdf(report.totalCommission)],
                  ['Stock Received (Restock Investment)', CurrencyFormatter.formatPdf(report.totalStockReceived)],
                  ['Current Stock Inventory Value', CurrencyFormatter.formatPdf(report.inventoryValue)],
                  ['Net Cash Flow (Revenue - Restocks)', CurrencyFormatter.formatPdf(report.netCashFlow)],
                  ['Total Outstanding Supplier Debt', CurrencyFormatter.formatPdf(report.totalOutstandingDebt)],
                ],
              ),
              pw.SizedBox(height: 16),
            ]);
          }

          if ((scope == ReportScope.full || scope == ReportScope.inventory) && report.breakdown.isNotEmpty) {
            var totInQty = 0;
            var totSoldQty = 0;
            var totInVal = 0.0;
            var totSoldVal = 0.0;
            final rows = report.breakdown.map((item) {
              totInQty += item.stockInQty;
              totSoldQty += item.soldQty;
              totInVal += item.stockInValue;
              totSoldVal += item.salesValue;
              return [
                item.itemName,
                item.unit,
                '${item.stockInQty}',
                CurrencyFormatter.formatPdf(item.stockInValue),
                '${item.soldQty}',
                CurrencyFormatter.formatPdf(item.salesValue),
              ];
            }).toList();
            rows.add([
              'TOTALS',
              '',
              '$totInQty',
              CurrencyFormatter.formatPdf(totInVal),
              '$totSoldQty',
              CurrencyFormatter.formatPdf(totSoldVal),
            ]);

            widgets.addAll([
              pw.Text('Inventory & Sales Breakdown by Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Item Name', 'Unit', 'Stock In (Qty)', 'Stock In Value', 'Sold (Qty)', 'Sales Value'],
                data: rows,
              ),
              pw.SizedBox(height: 16),
            ]);
          }

          if (scope == ReportScope.full && report.suppliersWithDebt.isNotEmpty) {
            widgets.addAll([
              pw.Text('Outstanding Supplier Debt Snapshot', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Supplier Name', 'Amount Owed (GH₵)'],
                data: report.suppliersWithDebt
                    .map((s) => [s.name, CurrencyFormatter.formatPdf(s.amountOwed)])
                    .toList(),
              ),
              pw.SizedBox(height: 16),
            ]);
          }

          widgets.add(
            pw.Text(
              'Generated by Apex Building Accessories & Hardware Shop Management System',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );

          return widgets;
        },
      ),
    );

    return doc;
  }

  static String _monthShort(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}
