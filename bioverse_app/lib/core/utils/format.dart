import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static String money(double amount, String currency) {
    if (currency == 'IDR') {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
    }
    return NumberFormat.currency(locale: 'en_US', symbol: currency == 'USD' ? '\$' : '$currency ', decimalDigits: 2)
        .format(amount);
  }

  static String number(num value) => NumberFormat.decimalPattern('en_US').format(value);

  static String compact(num value) => NumberFormat.compact(locale: 'en_US').format(value);

  static String date(DateTime? d) => d == null ? '-' : DateFormat('d MMM yyyy').format(d);

  static String dateTime(DateTime? d) => d == null ? '-' : DateFormat('d MMM yyyy, HH:mm').format(d);

  /// "2 weeks", "3 months" since [from].
  static String since(DateTime? from) {
    if (from == null) return 'Not planted yet';
    final days = DateTime.now().difference(from).inDays;
    if (days < 1) return 'Today';
    if (days < 14) return '$days day${days == 1 ? '' : 's'}';
    if (days < 60) return '${days ~/ 7} weeks';
    return '${days ~/ 30} months';
  }

  static String relative(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(d);
  }

  /// "open_for_donation" -> "Open for donation".
  static String enumLabel(String v) {
    if (v.isEmpty) return v;
    final s = v.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }
}
