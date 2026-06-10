import 'package:intl/intl.dart';

import '../../core/constants.dart';

/// Currency / weight / date formatting used across the UI.
class Fmt {
  Fmt._();

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: BusinessRules.currencySymbol,
    decimalDigits: 0,
  );

  static final _date = DateFormat('d MMM yyyy');
  static final _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final _month = DateFormat('MMM yyyy');

  static String money(num? amount) => _currency.format(amount ?? 0);

  static String grams(num? g) {
    if (g == null) return '0 g';
    // Show up to 2 decimals but trim trailing zeros (e.g. 1 g, 2.5 g).
    final s = g.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '$s g';
  }

  static String date(DateTime? d) => d == null ? '—' : _date.format(d.toLocal());

  static String dateTime(DateTime? d) =>
      d == null ? '—' : _dateTime.format(d.toLocal());

  static String month(DateTime? d) =>
      d == null ? '—' : _month.format(d.toLocal());

  /// A short, safe label for a raw id (e.g. when a user's name is unavailable).
  /// Never throws on empty/short ids.
  static String shortId(String? id, {String fallback = 'Unknown user'}) {
    if (id == null || id.isEmpty) return fallback;
    return 'User ${id.length <= 6 ? id : id.substring(0, 6)}';
  }
}
