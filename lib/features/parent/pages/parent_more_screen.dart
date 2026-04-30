// lib/features/parent/pages/parent_more_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:my_app/core/providers/locale_provider.dart';

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
  String? errorKey; // Store error key instead of hardcoded strings

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await checkAuthStatus(context);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;

    if (token == null || token!.isEmpty) {
      _forceLogout();
      return;
    }

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
        errorKey = "login_required";
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/parent/${widget.parentId}');

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
      );

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
          fullName = "${data['firstname'] ?? ''} ${data['lastname'] ?? ''}".trim();
          phoneNo = data['phoneno'] ?? '';
          isLoading = false;
          errorKey = null;
        });
        return;
      }

      if (response.statusCode == 404 ||
          response.body.contains("Parent not found")) {
        if (!mounted) return;
        setState(() {
          errorKey = "not_found";
          isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        errorKey = "error_loading";
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorKey = "server_failed";
        isLoading = false;
      });
    }
  }

  void _showLogoutConfirmation(BuildContext context, AppLocalizations l10n) {
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
            padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

                Text(
                  l10n.logOut,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  l10n.confirmLogOut,
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
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
                          child: Text(
                            l10n.logOut,
                            style: const TextStyle(fontWeight: FontWeight.w900),
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

  String _getErrorMessage(AppLocalizations l10n) {
    switch (errorKey) {
      case 'login_required':
        return l10n.loginRequiredError;
      case 'not_found':
        return l10n.accountDeletedError;
      case 'error_loading':
        return l10n.errorLoadingData;
      case 'server_failed':
        return l10n.serverConnectionFailed;
      default:
        return l10n.somethingWentWrongGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final showProfile = errorKey == null;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFC), Color(0xFFE6F4F3)],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: fetchParentInfo,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),

                if (errorKey != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getErrorMessage(l10n),
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
                  title: l10n.securitySettings,
                  isRtl: isRtl,
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
                  title: l10n.manageKids,
                  isRtl: isRtl,
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
                  title: l10n.termsAndPrivacy,
                  isRtl: isRtl,
                  onTap: () {
                    Navigator.pushNamed(context, '/termsPrivacy');
                  },
                ),

                const SizedBox(height: 16),

                // =====================================================================
                // 🌐 LANGUAGE CONVERTER BUTTON (START)
                // Copy this exact block of code to your child more screen!
                // Make sure to pass `isRtl` parameter locally in that file.
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
                  // onTap: () async {
                  //   final prefs = await SharedPreferences.getInstance();
                  //   final currentLang = prefs.getString('language_code') ?? 'en';
                  //   final newLang = currentLang == 'en' ? 'ar' : 'en';

                  //   await prefs.setString('language_code', newLang);

                  //   // ⚠️ IMPORTANT:
                  //   // Here you should trigger your state management to update the locale.
                  //   // For example, if using Provider: 
                  //   // Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(newLang));

                  //   if (context.mounted) {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       SnackBar(
                  //         content: Text(l10n.languageChangedHint),
                  //         backgroundColor: const Color(0xFF37C4BE),
                  //         behavior: SnackBarBehavior.floating,
                  //       ),
                  //     );
                  //   }
                  // },


                 onTap: () {
  final provider = Provider.of<LocaleProvider>(context, listen: false);
  if (isRtl) {
    provider.setLocale(const Locale('en'));
  } else {
    provider.setLocale(const Locale('ar'));
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.languageChangedHint))
  );
}, 
                ),
                // =====================================================================
                // 🌐 LANGUAGE CONVERTER BUTTON (END)
                // =====================================================================

                const SizedBox(height: 16),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: l10n.logOut,
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  isRtl: isRtl,
                  onTap: () {
                    _showLogoutConfirmation(context, l10n);
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
    required bool isRtl,
    Widget? trailingWidget, // Optional custom trailing widget
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
        trailing: trailingWidget ?? Icon(
          isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
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