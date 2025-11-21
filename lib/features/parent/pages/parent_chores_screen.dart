// lib/features/parent/pages/parent_chores_screen.dart
import 'package:flutter/material.dart';

class ParentChoresScreen extends StatelessWidget {
  final int parentId;
  final String token;

  const ParentChoresScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color(0xFFF7F8FA),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            "Chores screen will be implemented later",
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
