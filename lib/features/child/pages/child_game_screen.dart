import 'package:flutter/material.dart';
import 'package:my_app/utils/check_auth.dart';

class ChildGameScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String token;

  const ChildGameScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<ChildGameScreen> createState() => _ChildGameScreenState();
}

class _ChildGameScreenState extends State<ChildGameScreen> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    await checkAuthStatus(context);
    if (mounted) {
      setState(() => _checkingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return const Center(
      child: Text('Game Screen', style: TextStyle(fontSize: 18)),
    );
  }
}
