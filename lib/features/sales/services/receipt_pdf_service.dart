import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class ReceiptData {
  ReceiptData({
    required this.receiptNo,
    required this.customerName,
    required this.dispatchedAt,
    required this.items,
    required this.totalAmount,
    this.shopName = 'Apex Building Accessories',
    this.discountNote,
    this.subtotal,
  });

  final String receiptNo;
  final String customerName;
  final DateTime dispatchedAt;
  final List<ReceiptLine> items;
  final double totalAmount;
  final String shopName;
  final String? discountNote;
  final double? subtotal;
}

class ReceiptLine {
  ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.sellingPrice,
  });

  final String name;
  final int quantity;
  final String unit;
  final double sellingPrice;

  double get lineTotal => sellingPrice * quantity;
}

class ReceiptPdfService {
  static Future<pw.Document> buildDocument(ReceiptData data) async {
    final pdf = pw.Document();
    final shopTitle = data.shopName.toUpperCase();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                shopTitle,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text('Hardware & Building Supplies', style: const pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 4),
              pw.Text(
                'OFFICIAL SALES RECEIPT',
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 0.5),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Receipt No: ${data.receiptNo}', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text(
                      'Date: ${DateFormatter.formatDateTime(data.dispatchedAt)}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text('Customer: ${data.customerName}', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Price', 'Total'],
                data: data.items
                    .map((item) => [
                          item.name,
                          '${item.quantity} ${item.unit}',
                          CurrencyFormatter.formatPdf(item.sellingPrice),
                          CurrencyFormatter.formatPdf(item.lineTotal),
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 6.5),
              ),
              if (data.subtotal != null && data.discountNote != null) ...[
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Subtotal: ${CurrencyFormatter.formatPdf(data.subtotal!)}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(data.discountNote!, style: const pw.TextStyle(fontSize: 7)),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL PAID: ${CurrencyFormatter.formatPdf(data.totalAmount)}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Divider(thickness: 0.5),
              pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 6.5)),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<File> saveToTempFile(ReceiptData data) async {
    final pdf = await buildDocument(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Receipt-${data.receiptNo}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareReceipt(ReceiptData data) async {
    final file = await saveToTempFile(data);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Your receipt from ${data.shopName} — ${data.receiptNo}',
    );
  }

  static Future<void> printReceipt(ReceiptData data) async {
    final pdf = await buildDocument(data);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
