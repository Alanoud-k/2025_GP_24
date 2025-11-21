import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildMoreScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String username;
  final String phoneNo;
  final String token;

  const ChildMoreScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.username,
    required this.phoneNo,
    required this.token,
  });

  @override
  State<ChildMoreScreen> createState() => _ChildMoreScreenState();
}

class _ChildMoreScreenState extends State<ChildMoreScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Simulate loading (UI effect)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => isLoading = false);
    });
  }

  // -----------------------------
  // LOGOUT FUNCTION
  // -----------------------------
  Future<void> _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Removes token, ids, role

    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
  }

  // -----------------------------
  // LOGOUT POPUP
  // -----------------------------
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  // -----------------------------
  // BUILD
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // USER PROFILE
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.teal,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.phoneNo,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // SECURITY SETTINGS
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: "Security settings",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/childSecuritySettings',
                          arguments: {
                            'childId': widget.childId,
                            'token': widget.token,
                            'baseUrl': widget.baseUrl,
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // TERMS
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: "Terms & privacy policy",
                      onTap: () =>
                          Navigator.pushNamed(context, '/termsPrivacy'),
                    ),

                    const SizedBox(height: 18),

                    // LOGOUT
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: "Log out",
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: _showLogoutConfirmation,
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
    );
  }

  // -----------------------------
  // MENU ITEM WIDGET
  // -----------------------------
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color titleColor = Colors.black,
    Color iconColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: titleColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
