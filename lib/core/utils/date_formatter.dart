import 'package:intl/intl.dart';

/// Date formatting helper utility
abstract class DateFormatter {
  static String formatShort(dynamic date) {
    if (date == null) return '—';
    try {
      final DateTime dt = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '—';
    }
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return '—';
    try {
      final DateTime dt = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return '—';
    }
  }
}
