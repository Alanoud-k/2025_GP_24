import 'package:flutter/material.dart';

class ChildRewardsScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;

  const ChildRewardsScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Rewards Screen',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
