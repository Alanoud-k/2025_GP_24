import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MorePage extends StatefulWidget {
  final int parentId;
  const MorePage({super.key, required this.parentId});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String fullName = '';
  String phoneNo = '';
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchParentInfo();
  }

  Future<void> fetchParentInfo() async {
    final url = Uri.parse('http://10.0.2.2:3000/api/parent/${widget.parentId}');
    print("📡 Fetching parent info from $url");

    try {
      final response = await http.get(url);
      print("📩 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fullName =
              "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();
          phoneNo = data['phoneNo'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching parent info: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
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
                Navigator.pop(context); // إغلاق النافذة
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
                Navigator.pop(context); // إغلاق النافذة
                _performLogout(context); // تنفيذ تسجيل الخروج
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
    // هنا يمكنك إضافة أي عمليات تنظيف إضافية إذا needed
    // مثل مسح البيانات المحلية، إغلاق الجلسات، etc.
    
    // التنقل إلى صفحة mobile مع إزالة كل الصفحات السابقة
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

                        const SizedBox(height: 40),

                        // 🧩 Menu Items
                       _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Security settings',
                        onTap: () {
                        Navigator.pushNamed(
                         context,
                       '/parentSecuritySettings',
                       arguments: {'parentId': widget.parentId},
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
                              arguments: {'parentId': widget.parentId},
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