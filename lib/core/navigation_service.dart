import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> pushReplacementNamed(String route, {Object? args}) async {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.pushReplacementNamed(ctx, route, arguments: args);
    }
  }
}
