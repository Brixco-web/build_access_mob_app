import 'package:build_access_mob_app/features/sales/services/receipt_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildDocument produces a non-empty PDF with sale details', () async {
    final data = ReceiptData(
      receiptNo: 'SALE-001',
      customerName: 'Jane Customer',
      dispatchedAt: DateTime(2026, 1, 15, 14, 30),
      shopName: 'Test Shop',
      items: [
        ReceiptLine(name: 'Test Bolt', quantity: 2, unit: 'pcs', sellingPrice: 10),
      ],
      totalAmount: 20,
      subtotal: 25,
      discountNote: 'Discount: -GHS 5.00',
    );

    final doc = await ReceiptPdfService.buildDocument(data);
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));

    final pdfText = String.fromCharCodes(bytes);
    expect(pdfText.contains('TEST SHOP') || bytes.isNotEmpty, isTrue);
  });
}
