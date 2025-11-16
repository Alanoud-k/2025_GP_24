import 'package:flutter/material.dart';

class ChildGameScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;

  const ChildGameScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Game Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
