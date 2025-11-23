import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

Future<void> checkAuthStatus(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  // If token is missing → logout
  if (token == null || token.isEmpty) {
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    }
  }
}
