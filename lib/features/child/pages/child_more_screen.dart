//import 'dart:io';
//import 'dart:convert';
import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';
//import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/providers/locale_provider.dart';
//import 'package:mime/mime.dart';
//import 'package:http_parser/http_parser.dart';

class ChildMoreScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String username;
  final String phoneNo;
  final String token;

  ChildMoreScreen({
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
  //bool uploading = false;

  @override
  void initState() {
    super.initState();

    // Ensure token is still valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });

    // Smooth page entry
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => isLoading = false);
    });
  }

  // ---------------------------------------------------------
  // اختيار صورة من الاستديو
  // ---------------------------------------------------------
  /*Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return; // المستخدم ألغى

    File file = File(picked.path);
    await _uploadAvatar(file);
  }*/

  // ---------------------------------------------------------
  // رفع الصورة للسيرفر
  // ---------------------------------------------------------
  /* Future<void> _uploadAvatar(File file) async {
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
  }*/

  // ---------------------------------------------------------
  // Logout
  // ---------------------------------------------------------
  void _performLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
  }

  void _showLogoutConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 10),
              Text(l10n.logOut, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            l10n.confirmLogOut,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(200, 152, 152, 152),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
            child: Text(
              l10n.logOut,
              style: const TextStyle(color: Colors.white),
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
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ---------------------------------------------------------
                      // ملف الطفل الشخصي
                      // ---------------------------------------------------------
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              //if (!uploading) _pickAvatar();
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.teal,
                                  // backgroundImage: (widget.avatarUrl != null)
                                  //     ? NetworkImage("${widget.baseUrl}${widget.avatarUrl}")
                                  //     : null,
                                  child: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),

                                // لودر عند الرفع
                                /*if (uploading)
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),*/
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

                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.termsAndPrivacy,
                        isRtl: isRtl,
                        onTap: () => Navigator.pushNamed(context, '/termsPrivacy'),
                      ),

                      const SizedBox(height: 18),

                      // =====================================================================
                      // 🌐 LANGUAGE CONVERTER BUTTON
                      // =====================================================================
                      _buildMenuItem(
                        icon: Icons.language,
                        title: l10n.switchLanguage,
                        isRtl: isRtl,
                        trailingWidget: Text(
                          isRtl ? "English" : "العربية",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37C4BE),
                          ),
                        ),
                        onTap: () {
                          final provider = Provider.of<LocaleProvider>(context, listen: false);
                          if (isRtl) {
                            provider.setLocale(const Locale('en'));
                          } else {
                            provider.setLocale(const Locale('ar'));
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.languageChangedHint),
                              backgroundColor: const Color(0xFF37C4BE),
                            )
                          );
                        }, 
                      ),
                      // =====================================================================

                      const SizedBox(height: 18),

                      _buildMenuItem(
                        icon: Icons.logout,
                        title: l10n.logOut,
                        titleColor: Colors.red,
                        iconColor: Colors.red,
                        isRtl: isRtl,
                        onTap: _showLogoutConfirmation,
                      ),

                      const Spacer(),
                    ],
                  ),
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
    required bool isRtl,
    Widget? trailingWidget, // لدعم عنصر مخصص في نهاية القائمة
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
        trailing: trailingWidget ?? Icon(
          isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, 
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}