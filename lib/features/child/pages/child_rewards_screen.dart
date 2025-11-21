import 'package:flutter/material.dart';

class ChildRewardsScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;
  final String token; // <-- NEW

  const ChildRewardsScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token, // <-- NEW
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Rewards Screen\nToken: $token',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
