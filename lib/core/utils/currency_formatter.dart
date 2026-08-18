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
}
