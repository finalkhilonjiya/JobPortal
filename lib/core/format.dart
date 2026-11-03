import 'package:intl/intl.dart';

String _trim(double v) {
  final s = v.toStringAsFixed(2);
  if (!s.contains('.')) return s;
  return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String inr(num v) => '₹${NumberFormat.decimalPattern('en_IN').format(v.round())}';

/// Short form: ₹45 Lac, ₹1.2 Cr, ₹12,500
String inrShort(num v) {
  if (v >= 10000000) return '₹${_trim(v / 10000000)} Cr';
  if (v >= 100000) return '₹${_trim(v / 100000)} Lac';
  return inr(v);
}

/// ₹12,500/mo | ₹1,800/night | ₹45 Lac | ₹1.2 Cr
String formatPrice(num price, {String purpose = 'rent', String unit = 'month'}) {
  if (purpose == 'sale' || unit == 'total') return inrShort(price);
  if (unit == 'night') return '${inr(price)}/night';
  if (unit == 'month') return '${inr(price)}/mo';
  return inr(price);
}

String digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

/// 10-digit Indian number -> +91XXXXXXXXXX
String normalizePhone(String input) {
  final d = digitsOnly(input);
  if (d.length == 10) return '+91$d';
  if (d.length == 12 && d.startsWith('91')) return '+$d';
  return '+$d';
}

String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String titleCase(String s) =>
    s.split(' ').map((w) => w.isEmpty ? w : cap(w.toLowerCase())).join(' ');

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return DateFormat('d MMM y').format(d);
}

String dateTimeLabel(DateTime d) => DateFormat('EEE, d MMM  h:mm a').format(d);
String dateLabel(DateTime d) => DateFormat('d MMM y').format(d);
String clock(DateTime d) => DateFormat('h:mm a').format(d);

String localityKey(String city, String locality) =>
    '${city.trim().toLowerCase()}|${locality.trim().toLowerCase()}';
