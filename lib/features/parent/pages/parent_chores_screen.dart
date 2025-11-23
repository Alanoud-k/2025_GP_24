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
  @override
  void initState() {
    super.initState();
    _initAuthCheck();
  }

  Future<void> _initAuthCheck() async {
    await checkAuthStatus(context); // ✅ same logic as other screens
  }

  @override
  Widget build(BuildContext context) {
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
