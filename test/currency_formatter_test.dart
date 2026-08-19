import 'package:build_access_mob_app/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatPdf uses ASCII GHS prefix for PDF compatibility', () {
    expect(CurrencyFormatter.formatPdf(10), 'GHS 10.00');
    expect(CurrencyFormatter.formatPdf(10), isNot(contains('₵')));
  });
}
