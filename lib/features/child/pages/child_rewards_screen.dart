import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/utils/check_auth.dart';

class ChildRewardsScreen extends StatelessWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildRewardsScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkAuthStatus(context), // 🔐 validate token
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Center(
          child: Text(
            'Rewards Screen\nToken: $token',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }
}
