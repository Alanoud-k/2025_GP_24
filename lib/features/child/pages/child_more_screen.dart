// //import 'dart:io';
// //import 'dart:convert';
// import 'package:flutter/material.dart';
// //import 'package:image_picker/image_picker.dart';
// //import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:my_app/utils/check_auth.dart';
// import 'package:my_app/l10n/app_localizations.dart';
// import 'package:provider/provider.dart';
// import 'package:my_app/core/providers/locale_provider.dart';
// //import 'package:mime/mime.dart';
// //import 'package:http_parser/http_parser.dart';

// class ChildMoreScreen extends StatefulWidget {
//   final int childId;
//   final String baseUrl;
//   final String username;
//   final String phoneNo;
//   final String token;

//   ChildMoreScreen({
//     super.key,
//     required this.childId,
//     required this.baseUrl,
//     required this.username,
//     required this.phoneNo,
//     required this.token,
//   });

//   @override
//   State<ChildMoreScreen> createState() => _ChildMoreScreenState();
// }

// class _ChildMoreScreenState extends State<ChildMoreScreen> {
//   bool isLoading = true;
//   //bool uploading = false;

//   @override
//   void initState() {
//     super.initState();

//     // Ensure token is still valid
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       checkAuthStatus(context);
//     });

//     // Smooth page entry
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (mounted) setState(() => isLoading = false);
//     });
//   }

//   // ---------------------------------------------------------
//   // Logout
//   // ---------------------------------------------------------
//   void _performLogout(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.clear();

//     if (!mounted) return;
//     Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
//   }

//   void _showLogoutConfirmation() {
//     final l10n = AppLocalizations.of(context)!;
//     showDialog(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           title: Row(
//             children: [
//               const Icon(Icons.logout, color: Colors.red),
//               const SizedBox(width: 10),
//               Text(l10n.logOut, style: const TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//           content: Text(
//             l10n.confirmLogOut,
//             style: const TextStyle(fontSize: 16),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               style: TextButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(200, 152, 152, 152),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 l10n.cancel,
//                 style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//                 _performLogout(context);
//               },
//             child: Text(
//               l10n.logOut,
//               style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ---------------------------------------------------------
//   // BUILD
//   // ---------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final isRtl = Directionality.of(context) == TextDirection.rtl;

//     return Scaffold(
//       extendBody: true,
//       backgroundColor: Colors.transparent,
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
//             begin: AlignmentDirectional.topCenter,
//             end: AlignmentDirectional.bottomCenter,
//           ),
//         ),
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator(color: Colors.teal))
//             : SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsetsDirectional.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 20),

//                       // ---------------------------------------------------------
//                       // ملف الطفل الشخصي
//                       // ---------------------------------------------------------
//                       Row(
//                         children: [
//                           GestureDetector(
//                             onTap: () {
//                               //if (!uploading) _pickAvatar();
//                             },
//                             child: Stack(
//                               alignment: Alignment.center,
//                               children: [
//                                 const CircleAvatar(
//                                   radius: 35,
//                                   backgroundColor: Colors.teal,
//                                   // backgroundImage: (widget.avatarUrl != null)
//                                   //     ? NetworkImage("${widget.baseUrl}${widget.avatarUrl}")
//                                   //     : null,
//                                   child: Icon(
//                                     Icons.person,
//                                     size: 32,
//                                     color: Colors.white,
//                                   ),
//                                 ),

//                                 // لودر عند الرفع
//                                 /*if (uploading)
//                                   const CircularProgressIndicator(
//                                     color: Colors.white,
//                                   ),*/
//                               ],
//                             ),
//                           ),

//                           const SizedBox(width: 16),

//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 widget.username,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 widget.phoneNo,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 40),

//                       _buildMenuItem(
//                         icon: Icons.privacy_tip_outlined,
//                         title: l10n.termsAndPrivacy,
//                         isRtl: isRtl,
//                         onTap: () => Navigator.pushNamed(context, '/termsPrivacy'),
//                       ),

//                       const SizedBox(height: 18),

//                       // =====================================================================
//                       // 🌐 LANGUAGE CONVERTER BUTTON
//                       // =====================================================================
//                       _buildMenuItem(
//                         icon: Icons.language,
//                         title: l10n.switchLanguage,
//                         isRtl: isRtl,
//                         trailingWidget: Text(
//                           isRtl ? "English" : "العربية",
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF37C4BE),
//                           ),
//                         ),
//                         onTap: () {
//                           final provider = Provider.of<LocaleProvider>(context, listen: false);
//                           if (isRtl) {
//                             provider.setLocale(const Locale('en'));
//                           } else {
//                             provider.setLocale(const Locale('ar'));
//                           }
                          
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(l10n.languageChangedHint),
//                               backgroundColor: const Color(0xFF37C4BE),
//                             )
//                           );
//                         }, 
//                       ),
//                       // =====================================================================

//                       const SizedBox(height: 18),

//                       _buildMenuItem(
//                         icon: Icons.logout,
//                         title: l10n.logOut,
//                         titleColor: Colors.red,
//                         iconColor: Colors.red,
//                         isRtl: isRtl,
//                         onTap: _showLogoutConfirmation,
//                       ),

//                       const Spacer(),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------
//   // عنصر القائمة
//   // ---------------------------------------------------------
//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     Color titleColor = Colors.black,
//     Color iconColor = Colors.black,
//     required bool isRtl,
//     Widget? trailingWidget, // لدعم عنصر مخصص في نهاية القائمة
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: iconColor),
//         title: Text(
//           title,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: titleColor,
//           ),
//         ),
//         trailing: trailingWidget ?? Icon(
//           isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, 
//           size: 16,
//           color: Colors.grey,
//         ),
//         onTap: onTap,
//       ),
//     );
//   }
// }

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/providers/locale_provider.dart';

class ChildMoreScreen extends StatefulWidget {
  final int childId;
  final String baseUrl;
  final String username;
  final String phoneNo;
  final String token;
  // يمكن إضافة avatarUrl هنا مستقبلاً لو أردت، لكننا سنعتمد على التخزين المحلي للسرعة

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
  bool uploading = false;
  File? _localAvatar; // لحفظ الصورة وعرضها فوراً للطفل
  String? _savedAvatarUrl; // الرابط القادم من الباك اند (ان وجد)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthStatus(context);
    });
    _loadSavedAvatar(); // جلب الصورة المحفوظة مسبقاً
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => isLoading = false);
    });
  }

  // قراءة الصورة المحفوظة (إن وجدت) لكي تظهر مباشرة
  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAvatarUrl = prefs.getString('child_avatar_url_${widget.childId}');
    });
  }

  // ---------------------------------------------------------
  // دوال اختيار ورفع الصورة
  // ---------------------------------------------------------
  void _showAvatarPicker() {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF37C4BE)),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.selectPhotoProof ?? "تغيير الصورة الشخصية", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) _uploadAvatar(File(picked.path));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt, size: 40, color: Color(0xFF37C4BE)),
                    const SizedBox(height: 8),
                    Text(l10n.camera ?? "الكاميرا", style: const TextStyle(color: Color(0xFF37C4BE), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(width: 1, height: 60, color: const Color(0xFF37C4BE).withOpacity(0.3)),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) _uploadAvatar(File(picked.path));
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library, size: 40, color: Color(0xFF37C4BE)),
                    const SizedBox(height: 8),
                    Text(l10n.gallery ?? "المعرض", style: const TextStyle(color: Color(0xFF37C4BE), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(File image) async {
    setState(() => uploading = true);
    try {
      // تحديث: ضع الرابط الصحيح للباك اند الخاص برفع صورة الطفل هنا
       final uri = Uri.parse('${widget.baseUrl}/api/auth/child/avatar/${widget.childId}');      var request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': 'Bearer ${widget.token}'})
        ..files.add(await http.MultipartFile.fromPath('avatar', image.path)); // تأكد أن اسم الحقل 'avatar' يطابق الباك اند

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = jsonDecode(responseBody);
        
        setState(() {
          _localAvatar = image; // تحديث الواجهة فوراً لتظهر للطفل
          uploading = false;
        });

        // حفظ الرابط الجديد في SharedPreferences لتقرأه صفحة Home
        if (data['avatarUrl'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('child_avatar_url_${widget.childId}', data['avatarUrl']);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم تحديث الصورة بنجاح! 🎉"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('فشل في رفع الصورة');
      }
    } catch (e) {
      setState(() => uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء رفع الصورة 😔"), backgroundColor: Colors.red),
        );
      }
    }
  }

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
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 10),
            Text(l10n.logOut, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(l10n.confirmLogOut, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(backgroundColor: const Color.fromARGB(200, 152, 152, 152), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              _performLogout(context);
            },
            child: Text(l10n.logOut, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
                              if (!uploading) _showAvatarPicker();
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                            CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.teal,
                                  backgroundImage: _localAvatar != null
                                      ? FileImage(_localAvatar!) as ImageProvider
                                      : (_savedAvatarUrl != null && _savedAvatarUrl!.isNotEmpty
                                          ? NetworkImage(_savedAvatarUrl!.startsWith('http') ? _savedAvatarUrl! : "${widget.baseUrl}$_savedAvatarUrl")
                                          : null),
                                  child: _localAvatar == null && (_savedAvatarUrl == null || _savedAvatarUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 32, color: Colors.white)
                                      : null,
                                ),
                                if (uploading)
                                  const CircularProgressIndicator(color: Colors.white),
                                // أيقونة صغيرة تدل على إمكانية التعديل
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.edit, size: 14, color: Colors.teal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(widget.phoneNo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      _buildMenuItem(icon: Icons.privacy_tip_outlined, title: l10n.termsAndPrivacy, isRtl: isRtl, onTap: () => Navigator.pushNamed(context, '/termsPrivacy')),
                      const SizedBox(height: 18),
                      _buildMenuItem(
                        icon: Icons.language,
                        title: l10n.switchLanguage,
                        isRtl: isRtl,
                        trailingWidget: Text(isRtl ? "English" : "العربية", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF37C4BE))),
                        onTap: () {
                          final provider = Provider.of<LocaleProvider>(context, listen: false);
                          if (isRtl) {
                            provider.setLocale(const Locale('en'));
                          } else {
                            provider.setLocale(const Locale('ar'));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.languageChangedHint), backgroundColor: const Color(0xFF37C4BE)));
                        },
                      ),
                      const SizedBox(height: 18),
                      _buildMenuItem(icon: Icons.logout, title: l10n.logOut, titleColor: Colors.red, iconColor: Colors.red, isRtl: isRtl, onTap: _showLogoutConfirmation),
                      const Spacer(),
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
    required bool isRtl,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: titleColor)),
        trailing: trailingWidget ?? Icon(isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}