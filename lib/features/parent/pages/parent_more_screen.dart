// lib/features/parent/pages/parent_more_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';

class MorePage extends StatefulWidget {
  final int parentId;
  final String token;

  const MorePage({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String fullName = '';
  String phoneNo = '';

  bool isLoading = true;
  String? errorMessage; // بدل hasError العشوائي

  @override
  void initState() {
    super.initState();

    // ✅ لا تسوين checkAuthStatus إذا الـ token جايك جاهز
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.token.isEmpty) {
        checkAuthStatus(context);
      }
    });

    fetchParentInfo();
  }

  Future<void> fetchParentInfo() async {
    // ✅ Guard: إذا ما فيه parentId
    if (widget.parentId == 0) {
      if (!mounted) return;
      setState(() {
        errorMessage = "لازم تسوين تسجيل دخول من جديد.";
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'http://10.0.2.2:3000/api/parent/${widget.parentId}',
    );
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

      // ✅ 401: توكن منتهي → طلّعيه فورًا بدون ما تعرضين Failed to load
      if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/mobile',
            (_) => false,
          );
        }
        return;
      }

      // ✅ 200: تمام
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          fullName =
              "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}".trim();
          phoneNo = data['phoneno'] ?? '';
          isLoading = false;
          errorMessage = null;
        });
        return;
      }

      // ✅ 404 / Parent not found
      if (response.statusCode == 404 ||
          response.body.contains("Parent not found")) {
        if (!mounted) return;
        setState(() {
          errorMessage = "هذا الحساب محذوف أو غير موجود.";
          isLoading = false;
        });
        return;
      }

      // ✅ أي خطأ ثاني
      if (!mounted) return;
      setState(() {
        errorMessage = "صار خطأ في تحميل البيانات.";
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching parent info: $e");
      if (!mounted) return;
      setState(() {
        errorMessage = "تعذّر الاتصال بالسيرفر.";
        isLoading = false;
      });
    }
  }

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
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/mobile',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProfile = errorMessage == null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: fetchParentInfo,
        child: Container(
          color: Colors.grey[100],
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
              : ListView(
                  children: [
                    const SizedBox(height: 10),

                    // ✅ لو فيه خطأ (مثل حساب محذوف) اعرضي رسالة بس لا توقفي الصفحة
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

                    // ✅ كرت البروفايل (إذا البيانات موجودة)
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
