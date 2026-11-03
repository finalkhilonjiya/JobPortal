import 'package:intl/intl.dart';

String _trim(double v) {
  final s = v.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// ₹12,500/mo  |  ₹1,800/night  |  ₹45 Lac  |  ₹1.2 Cr
String formatPrice(num price, {String purpose = 'rent', String unit = 'month'}) {
  if (purpose == 'sale' || unit == 'total') {
    if (price >= 10000000) return '₹${_trim(price / 10000000)} Cr';
    if (price >= 100000) return '₹${_trim(price / 100000)} Lac';
    return '₹${NumberFormat.decimalPattern('en_IN').format(price)}';
  }
  final body = '₹${NumberFormat.decimalPattern('en_IN').format(price)}';
  if (unit == 'night') return '$body/night';
  if (unit == 'month') return '$body/mo';
  return body;
}

String digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

/// 10-digit Indian number -> +91XXXXXXXXXX
String normalizePhone(String input) {
  final d = digitsOnly(input);
  if (d.length == 10) return '+91$d';
  if (d.length == 12 && d.startsWith('91')) return '+$d';
  return '+$d';
}
