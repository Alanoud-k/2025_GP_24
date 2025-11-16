import 'package:flutter/material.dart';

class ChildCardScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;

  const ChildCardScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Card Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
