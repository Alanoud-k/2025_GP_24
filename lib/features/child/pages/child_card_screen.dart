import 'package:flutter/material.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildCardScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildCardScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildCardScreen> createState() => _ChildCardScreenState();
}

class _ChildCardScreenState extends State<ChildCardScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await checkAuthStatus(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Card Screen', style: TextStyle(fontSize: 18)),
    );
  }
}
