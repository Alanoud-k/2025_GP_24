import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> checkAuthStatus(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  // No token → send user to mobile entry
  if (token == null || token.isEmpty) {
    _redirectToEntry(context);
    return;
  }

  // Do nothing else here – backend 401 will handle expiration automatically
}

void handleUnauthorized(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  _redirectToEntry(context);
}

void _redirectToEntry(BuildContext context) {
  Navigator.pushNamedAndRemoveUntil(context, '/mobile-entry', (route) => false);
}
