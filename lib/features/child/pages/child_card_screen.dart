import 'package:flutter/material.dart';

class ChildCardScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;
  final String token; // <-- ADDED

  const ChildCardScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token, // <-- ADDED
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Card Screen', style: TextStyle(fontSize: 18)),
    );
  }
}
