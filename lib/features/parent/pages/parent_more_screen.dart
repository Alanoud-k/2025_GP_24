// lib/features/parent/pages/parent_more_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';

class MorePage extends StatefulWidget {
  final int parentId;
  final String token;

  const MorePage({super.key, required this.parentId, required this.token});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String fullName = '';
  String phoneNo = '';
  String? token;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    // Step 1 — check expired
    await checkAuthStatus(context);

    // Step 2 — load token
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    // Step 3 — if missing → logout
    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }

    // Step 4 — load info
    await fetchParentInfo();
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    }
  }

  Future<void> fetchParentInfo() async {
    if (widget.parentId == 0) {
      if (!mounted) return;
      setState(() {
        errorMessage = "لازم تسوين تسجيل دخول من جديد.";
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/parent/${widget.parentId}');
    print("Fetching parent info from $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

      print("Response: ${response.body}");

      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          fullName = "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}"
              .trim();
          phoneNo = data['phoneno'] ?? '';
          isLoading = false;
          errorMessage = null;
        });
        return;
      }

      if (response.statusCode == 404 ||
          response.body.contains("Parent not found")) {
        if (!mounted) return;
        setState(() {
          errorMessage = "This account was deleted or does not exist.";
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        errorMessage = "An error occurred while loading data.";
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching parent info: $e");
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to connect to the server.";
        isLoading = false;
      });
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    const kTextDark = Color(0xFF2C3E50);
    const kRed = Color(0xFFE74C3C);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // soft icon circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kRed.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: kRed,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  "Log Out",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Are you sure you want to log out?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kTextDark,
                            side: BorderSide(
                              color: Colors.black12.withOpacity(0.14),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _performLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Log Out",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performLogout() async {
    await _forceLogout();
  }

  @override
  Widget build(BuildContext context) {
    final showProfile = errorMessage == null;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: fetchParentInfo,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),

                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (showProfile)
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.teal,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phoneNo,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Security settings',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/parentSecuritySettings',
                      arguments: {
                        'parentId': widget.parentId,
                        'token': widget.token,
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.family_restroom_outlined,
                  title: 'Manage Kids',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/manageKids',
                      arguments: {
                        'parentId': widget.parentId,
                        'token': widget.token,
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Terms & privacy policy',
                  onTap: () {
                    Navigator.pushNamed(context, '/termsPrivacy');
                  },
                ),

                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Log out',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color titleColor = Colors.black,
    Color iconColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
