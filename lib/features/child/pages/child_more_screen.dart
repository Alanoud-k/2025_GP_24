import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ChildMoreScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String username;
  final String phoneNo;
  final String token;
  String? avatarUrl; // ← الصورة القادمة من السيرفر

  ChildMoreScreen({
    super.key,
    required this.childId,
    required this.baseUrl,
    required this.username,
    required this.phoneNo,
    required this.token,
    this.avatarUrl,
  });

  @override
  State<ChildMoreScreen> createState() => _ChildMoreScreenState();
}

class _ChildMoreScreenState extends State<ChildMoreScreen> {
  bool isLoading = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();

    // Check token
    checkAuthStatus(context);

    // Smooth loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => isLoading = false);
    });
  }

  // ---------------------------------------------------------
  // اختيار صورة من الاستديو
  // ---------------------------------------------------------
  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return; // المستخدم ألغى

    File file = File(picked.path);
    await _uploadAvatar(file);
  }

  // ---------------------------------------------------------
  // رفع الصورة للسيرفر
  // ---------------------------------------------------------
  Future<void> _uploadAvatar(File file) async {
    setState(() => uploading = true);

    final url = Uri.parse(
      "${widget.baseUrl}/api/auth/child/upload-avatar/${widget.childId}",
    );

    final request = http.MultipartRequest("POST", url);

    // لو عندك Authorization
    request.headers['Authorization'] = "Bearer ${widget.token}";

    // CHANGED: set correct MIME type so multer sees image/jpeg or image/png
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    final mediaType = MediaType(parts[0], parts[1]);

    request.files.add(
      await http.MultipartFile.fromPath(
        "avatar",
        file.path,
        contentType: mediaType,
      ),
    );

    final res = await request.send();
    final body = await res.stream.bytesToString();

    if (res.statusCode == 200) {
      final data = jsonDecode(body);

      setState(() {
        widget.avatarUrl = data['avatarUrl']; // CHANGED: full Cloudinary URL
        uploading = false;
      });
    } else {
      setState(() => uploading = false);
      debugPrint("Upload error: $body");
    }
  }

  // ---------------------------------------------------------
  // تسجيل الخروج
  // ---------------------------------------------------------
  void _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
  }

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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    print("BASE URL = ${widget.baseUrl}");
    print("AVATAR URL = ${widget.avatarUrl}");
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

                    // ---------------------------------------------------------
                    //  ملف الطفل الشخصي
                    // ---------------------------------------------------------
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!uploading) _pickAvatar();
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // صورة الطفل أو placeholder
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.teal,
                                backgroundImage: (widget.avatarUrl != null)
                                    ? NetworkImage(
                                        "${widget.baseUrl}${widget.avatarUrl}",
                                      )
                                    : null,
                                child: (widget.avatarUrl == null)
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 32,
                                      )
                                    : null,
                              ),

                              // لودر عند الرفع
                              if (uploading)
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),

                              // زر تعديل صغير (دائري)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
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

                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: "Terms & privacy policy",
                      onTap: () =>
                          Navigator.pushNamed(context, '/termsPrivacy'),
                    ),

                    const SizedBox(height: 18),

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

  // ---------------------------------------------------------
  // عنصر القائمة
  // ---------------------------------------------------------
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
