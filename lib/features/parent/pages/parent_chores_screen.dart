// lib/features/parent/pages/parent_chores_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart'; // ✅ ADD THIS

class ParentChoresScreen extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentChoresScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentChoresScreen> createState() => _ParentChoresScreenState();
}

class _ParentChoresScreenState extends State<ParentChoresScreen> {
  bool _loading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _initializeAuthCheck();
  }

  Future<void> _initializeAuthCheck() async {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return SafeArea(
      child: Container(
        color: const Color(0xFFF7F8FA),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            "Chores screen will be implemented later",
            style: TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
