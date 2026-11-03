import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/anim.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../screens/auth/login_screen.dart';
import '../services/api.dart';

void toast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
}

/// Returns true when the user is (or just became) logged in.
Future<bool> ensureLogin(BuildContext context, {String reason = 'Log in to continue'}) async {
  if (Api.loggedIn) return true;
  final ok = await Navigator.of(context).push<bool>(fadeRoute(LoginScreen(reason: reason)));
  return ok == true && Api.loggedIn;
}

Future<bool> confirmDialog(BuildContext context, String title, String message,
    {String yes = 'Yes', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(title, style: AppText.h3),
      content: Text(message, style: AppText.bodyM),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes, style: TextStyle(color: danger ? AppColors.danger : AppColors.primary)),
        ),
      ],
    ),
  );
  return r == true;
}

Future<void> openUrl(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) toast(context, 'Could not open the link.');
  } catch (_) {
    if (context.mounted) toast(context, 'Could not open the link.');
  }
}

Future<void> callPhone(BuildContext context, String phone) => openUrl(context, 'tel:$phone');

Future<void> openWhatsApp(BuildContext context, String phone, String text) {
  final d = digitsOnly(phone);
  return openUrl(context, 'https://wa.me/$d?text=${Uri.encodeComponent(text)}');
}

/// Opens Google Maps (app or browser) - no in-app map needed.
Future<void> openInMaps(BuildContext context, {double? lat, double? lng, String query = ''}) {
  final String url;
  if (lat != null && lng != null) {
    url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  } else {
    url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }
  return openUrl(context, url);
}

Future<void> openNearbyInMaps(BuildContext context, String what, {double? lat, double? lng, String area = ''}) {
  final q = lat != null && lng != null ? '$what near $lat,$lng' : '$what near $area';
  return openUrl(context, 'https://www.google.com/maps/search/${Uri.encodeComponent(q)}');
}

Future<T?> showSheet<T>(BuildContext context, Widget child, {bool full = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * (full ? 0.94 : 0.88)),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4)),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}
