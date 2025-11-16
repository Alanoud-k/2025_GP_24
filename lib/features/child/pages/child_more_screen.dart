import 'package:flutter/material.dart';

class ChildMoreScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;

  const ChildMoreScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'More Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
