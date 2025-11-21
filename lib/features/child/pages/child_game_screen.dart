import 'package:flutter/material.dart';

class ChildGameScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;
  final String token; // <-- ADD TOKEN

  const ChildGameScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token, // <-- ADD TOKEN
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Game Screen', style: TextStyle(fontSize: 18)),
    );
  }
}
