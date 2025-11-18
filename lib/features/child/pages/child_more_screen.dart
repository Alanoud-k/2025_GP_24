import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChildMoreScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String username;
  final String phoneNo;
  
  const ChildMoreScreen({
    super.key, 
    required this.childId,
    required this.baseUrl,
    required this.username,
    required this.phoneNo,
  });

  @override
  State<ChildMoreScreen> createState() => _ChildMoreScreenState();
}

class _ChildMoreScreenState extends State<ChildMoreScreen> {
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    // محاكاة تحميل البيانات
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  // دالة عرض نافذة تأكيد تسجيل الخروج
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // دالة تنفيذ تسجيل الخروج
  void _performLogout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/mobile',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : hasError
                  ? const Center(
                      child: Text(
                        "Failed to load data",
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // 🟢 User Info
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.teal,
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
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

                        // 🧩 Menu Items
                       _buildMenuItem(
                         icon: Icons.lock_outline,
                         title: 'Security settings',
                         onTap: () {
                          Navigator.pushNamed(
                            context,
                              '/childSecuritySettings',
                            arguments: {
                        'childId': widget.childId,
                        'baseUrl': widget.baseUrl,
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

                        const Spacer(),
                      ],
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
            color: Colors.black.withOpacity(0.1),
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
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}