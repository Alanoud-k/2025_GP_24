import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart'; // ✅ ADD THIS

class ParentAllowanceScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentAllowanceScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentAllowanceScreen> createState() => _ParentAllowanceScreenState();
}

class _ParentAllowanceScreenState extends State<ParentAllowanceScreen> {
  bool _loading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await checkAuthStatus(context);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }

    if (mounted) setState(() => _loading = false);
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (route) => false);
    }
  }

  Future<void> _handleAuth() async {
    await checkAuthStatus(context); // ✅ redirects if token expired
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return const Scaffold(
      backgroundColor: Color(0xFFF7F8FA),
      body: SafeArea(
        child: Center(
          child: Text(
            "Allowance page is empty for now.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
