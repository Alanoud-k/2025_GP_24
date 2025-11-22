import 'package:flutter/material.dart';

class ParentAllowanceScreen extends StatelessWidget {
  final int parentId;
  final String token;

  const ParentAllowanceScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder screen
    return const Scaffold(
      backgroundColor: Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: Text(
            "Allowance page is empty for now.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
