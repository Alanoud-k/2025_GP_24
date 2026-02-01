import 'package:flutter/material.dart';

class UiFeedback {
  // Hassala style colors
  static const Color _success = Color(0xFF2EA49E);
  static const Color _error = Color(0xFFE74C3C);
  static const Color _info = Color(0xFF2C3E50);

  /// Unified SnackBar (use for most errors + quick success/info)
  static void snack(
    BuildContext context,
    String message, {
    UiFeedbackType type = UiFeedbackType.info,
  }) {
    final color = switch (type) {
      UiFeedbackType.success => _success,
      UiFeedbackType.error => _error,
      UiFeedbackType.info => _info,
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  /// Unified Dialog (use for important errors / confirmations)
  static Future<void> dialog(
    BuildContext context, {
    required String title,
    required String message,
    UiFeedbackType type = UiFeedbackType.info,
    String buttonText = "OK",
  }) {
    final color = switch (type) {
      UiFeedbackType.success => _success,
      UiFeedbackType.error => _error,
      UiFeedbackType.info => _info,
    };

    final icon = switch (type) {
      UiFeedbackType.success => Icons.check_circle_rounded,
      UiFeedbackType.error => Icons.error_rounded,
      UiFeedbackType.info => Icons.info_rounded,
    };

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.4, color: Colors.black54),
        ),
        actions: [
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum UiFeedbackType { success, error, info }
