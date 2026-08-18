import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

/// PDF Receipt Generator Service for Flutter Mobile
class ReceiptPdfService {
  static Future<void> generateAndShareReceipt({
    required String receiptNo,
    required String customerName,
    required String issuedBy,
    required DateTime dispatchedAt,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'APEX BUILDING ACCESSORIES',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'Hardware & Building Supplies',
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'OFFICIAL SALES RECEIPT',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(thickness: 0.5),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Receipt No: $receiptNo', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Date: ${DateFormatter.formatDateTime(dispatchedAt)}', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Customer: $customerName', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Staff: $issuedBy', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Total'],
                data: items.map((item) {
                  final double price = (item['sellingPrice'] as num).toDouble();
                  final double lineTotal = price * (item['quantity'] as num);
                  return [
                    item['name'] ?? 'Item',
                    '${item['quantity']} ${item['unit'] ?? 'pcs'}',
                    CurrencyFormatter.format(price),
                    CurrencyFormatter.format(lineTotal),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 6.5),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL PAID: ${CurrencyFormatter.format(totalAmount)}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Divider(thickness: 0.5),
              pw.Text(
                'Thank you for your business!',
                style: const pw.TextStyle(fontSize: 6.5),
              ),
              pw.Text(
                'Goods sold in good order. No refund after 7 days.',
                style: const pw.TextStyle(fontSize: 6),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt-$receiptNo.pdf',
    );
  }
}
