import 'package:intl/intl.dart';

/// Formats numbers to Ghanaian Cedi (GH₵) currency format
abstract class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: 'GH₵ ',
    decimalDigits: 2,
    locale: 'en_GH',
  );

  static String format(num? amount) {
    return _formatter.format(amount ?? 0);
  }

  /// PDF-safe currency text (Helvetica lacks GH₵ glyph U+20B5).
  static String formatPdf(num? amount) {
    final value = (amount ?? 0).toDouble();
    return 'GHS ${value.toStringAsFixed(2)}';
  }
}
