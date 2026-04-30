import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/utils/check_auth.dart';
import 'package:my_app/core/api_config.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ParentSecuritySettingsPage extends StatefulWidget {
  final int parentId;
  final String token;

  const ParentSecuritySettingsPage({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<ParentSecuritySettingsPage> createState() =>
      _ParentSecuritySettingsPageState();
}

class _ParentSecuritySettingsPageState
    extends State<ParentSecuritySettingsPage> {
  // Hassala palette
  static const Color kBg1 = Color(0xFFF7FAFC);
  static const Color kBg2 = Color(0xFFE6F4F3);
  static const Color kTextDark = Color(0xFF2C3E50);
  static const Color kGreen1 = Color(0xFF37C4BE);
  static const Color kGreen2 = Color(0xFF2EA49E);

  List<dynamic> children = [];
  bool isLoadingChildren = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await checkAuthStatus(context);
    await _loadToken();
    await fetchChildren();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token") ?? widget.token;
  }

  Future<bool> _handleExpired(http.Response res) async {
    if (res.statusCode != 401) return false;

    String msg = "";
    try {
      final data = jsonDecode(res.body);
      msg = (data["message"] ?? data["error"] ?? "").toString().toLowerCase();
    } catch (_) {
      msg = res.body.toLowerCase();
    }

    final looksLikeTokenIssue =
        msg.contains("token") ||
        msg.contains("jwt") ||
        msg.contains("expired") ||
        msg.contains("unauthorized") ||
        msg.contains("invalid signature");

    if (!looksLikeTokenIssue) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return true;
    Navigator.pushNamedAndRemoveUntil(context, '/mobile', (_) => false);
    return true;
  }

  Future<void> fetchChildren() async {
    setState(() => isLoadingChildren = true);

    if (token == null) {
      // Use standard delay to fetch l10n to prevent errors if context is not ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorBar(AppLocalizations.of(context)!.missingTokenLoginAgain);
      });
      setState(() => isLoadingChildren = false);
      return;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/children',
    );

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (await _handleExpired(response)) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          children = data is List ? data : (data["children"] ?? []);
        });
      } else {
        if (mounted) _showErrorBar(AppLocalizations.of(context)!.failedToLoadChildrenBasic);
      }
    } catch (e) {
      if (mounted) _showErrorBar(AppLocalizations.of(context)!.errorPrefixMsg(e.toString()));
    } finally {
      if (mounted) setState(() => isLoadingChildren = false);
    }
  }

  String _extractMessage(
    http.Response res, {
    required String fallback,
  }) {
    try {
      final data = jsonDecode(res.body);
      final msg =
          data["error"] ?? data["message"] ?? data["msg"] ?? data["details"];

      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }

      return fallback;
    } catch (_) {
      final raw = res.body.toString().trim();
      return raw.isNotEmpty ? raw : fallback;
    }
  }

  // -------------------------------------------------------------
  // CHANGE PARENT PASSWORD 
  // -------------------------------------------------------------
  void _showChangeParentPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;
    bool busy = false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) { // 👈 غيرنا اسم الـ context هنا لنتفادى التعارض
        return StatefulBuilder(
          builder: (ctx, setModal) {
            
            // ✅ الدالة المصححة
            Future<void> onSubmit() async {
              if (busy) return;
              if (!formKey.currentState!.validate()) return;

              setModal(() => busy = true);

              final success = await _changeParentPassword(
                currentPassword.text.trim(),
                newPassword.text.trim(),
                l10n,
              );

              setModal(() => busy = false);

              // 👈 نغلق النافذة باستخدام הـ context الخاص بها
              if (success && mounted) {
                Navigator.pop(bottomSheetContext); 
              }
            }

            return Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 18),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsetsDirectional.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),

                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kGreen1.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.lock_rounded,
                                color: kGreen1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.changePasswordTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(bottomSheetContext), // 👈
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel(l10n.currentPasswordLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: currentPassword,
                          obscureText: !showCurrent,
                          textInputAction: TextInputAction.next,
                          decoration: _hassalaFieldDeco(
                            hint: l10n.enterCurrentPasswordHint,
                            prefix: Icons.key_rounded,
                            suffix: IconButton(
                              onPressed: () =>
                                  setModal(() => showCurrent = !showCurrent),
                              icon: Icon(
                                showCurrent
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return l10n.requiredField;
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel(l10n.newPasswordLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPassword,
                          obscureText: !showNew,
                          textInputAction: TextInputAction.next,
                          decoration: _hassalaFieldDeco(
                            hint: l10n.createStrongPasswordHint,
                            prefix: Icons.lock_outline_rounded,
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.requirementsTooltip,
                                  onPressed: () =>
                                      _showPasswordRequirements(context, l10n),
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setModal(() => showNew = !showNew),
                                  icon: Icon(
                                    showNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          validator: (v) {
                            final pass = (v ?? "").trim();
                            if (pass.isEmpty) return l10n.requiredField;
                            if (!_validatePassword(pass))
                              return l10n.doesNotMeetRequirements;
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel(l10n.confirmNewPasswordLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPassword,
                          obscureText: !showConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => onSubmit(),
                          decoration: _hassalaFieldDeco(
                            hint: l10n.reEnterNewPasswordHint,
                            prefix: Icons.verified_user_outlined,
                            suffix: IconButton(
                              onPressed: () =>
                                  setModal(() => showConfirm = !showConfirm),
                              icon: Icon(
                                showConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (v) {
                            final c = (v ?? "").trim();
                            if (c.isEmpty) return l10n.requiredField;
                            if (c != newPassword.text.trim())
                              return l10n.passwordsDoNotMatchVal;
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black12.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: kGreen2,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.passwordRequirementsDesc,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => Navigator.pop(bottomSheetContext), // 👈
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kTextDark,
                                    side: BorderSide(
                                      color: Colors.black12.withOpacity(0.12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.cancelBtn,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: busy ? null : onSubmit, // 👈 استدعاء مباشر
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen1,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          l10n.changeBtn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _changeParentPassword(
    String currentPassword,
    String newPassword,
    AppLocalizations l10n,
  ) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/auth/parent/${widget.parentId}/password",
    );

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );

      if (await _handleExpired(response)) return false;

      if (response.statusCode == 200) {
        _showSuccessBar(l10n.passwordChangedSuccess);
        return true;
      }
      final msg = _extractMessage(
        response,
        fallback: l10n.failedToChangePasswordFallback,
      );
      _showErrorBar(msg);
      return false;
    } catch (_) {
      _showErrorBar(l10n.networkErrorTryAgain);
      return false;
    }
  }

  // -------------------------------------------------------------
  // CHANGE CHILD PASSWORD 
  // -------------------------------------------------------------
  void _showChangeChildPasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    String? selectedChild;
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    bool showNew = false;
    bool showConfirm = false;
    bool busy = false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) { // 👈 تغيير الاسم هنا أيضاً
        return StatefulBuilder(
          builder: (ctx, setModal) {
            
            // ✅ الدالة المصححة للطفل
            Future<void> onSubmit() async {
              if (busy) return;
              if (!formKey.currentState!.validate()) return;

              setModal(() => busy = true);

              final success = await _changeChildPassword(
                int.parse(selectedChild!),
                newPassword.text.trim(),
                l10n,
              );

              setModal(() => busy = false);

              if (success && mounted) {
                Navigator.pop(bottomSheetContext); // 👈 إغلاق صحيح
              }
            }

            return Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 18),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsetsDirectional.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),

                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: kGreen2.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.child_care_rounded,
                                color: kGreen2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.changeChildPasswordTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(bottomSheetContext), // 👈
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel(l10n.selectChildLabel),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedChild,
                          isExpanded: true,
                          decoration: _hassalaFieldDeco(
                            hint: l10n.chooseHint,
                            prefix: Icons.person_outline_rounded,
                          ),
                          items: children.map((c) {
                            return DropdownMenuItem<String>(
                              value: c['childId'].toString(),
                              child: Text(
                                (c['firstName'] ?? l10n.childFallback).toString(),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setModal(() => selectedChild = v),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? l10n.requiredField : null,
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel(l10n.newPasswordLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPassword,
                          obscureText: !showNew,
                          decoration: _hassalaFieldDeco(
                            hint: l10n.createStrongPasswordHint,
                            prefix: Icons.lock_outline_rounded,
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.requirementsTooltip,
                                  onPressed: () =>
                                      _showPasswordRequirements(context, l10n),
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setModal(() => showNew = !showNew),
                                  icon: Icon(
                                    showNew
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          validator: (v) {
                            final pass = (v ?? "").trim();
                            if (pass.isEmpty) return l10n.requiredField;
                            if (!_validatePassword(pass))
                              return l10n.doesNotMeetRequirements;
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _fieldLabel(l10n.confirmPasswordLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPassword,
                          obscureText: !showConfirm,
                          decoration: _hassalaFieldDeco(
                            hint: l10n.reEnterNewPasswordHint,
                            prefix: Icons.verified_user_outlined,
                            suffix: IconButton(
                              onPressed: () =>
                                  setModal(() => showConfirm = !showConfirm),
                              icon: Icon(
                                showConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: (v) {
                            final c = (v ?? "").trim();
                            if (c.isEmpty) return l10n.requiredField;
                            if (c != newPassword.text.trim())
                              return l10n.passwordsDoNotMatchVal;
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => Navigator.pop(bottomSheetContext), // 👈
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kTextDark,
                                    side: BorderSide(
                                      color: Colors.black12.withOpacity(0.12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.cancelBtn,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: (busy || children.isEmpty) ? null : onSubmit, // 👈 استدعاء مباشر
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen2,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          l10n.changeBtn,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _changeChildPassword(int childId, String newPassword, AppLocalizations l10n) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/auth/child/$childId/password",
    );

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"newPassword": newPassword}),
      );

      if (await _handleExpired(response)) return false;

      if (response.statusCode == 200) {
        _showSuccessBar(l10n.childPasswordChangedSuccess);
        return true;
      } else {
        _showErrorBar(
          _extractMessage(response, fallback: l10n.failedToChangePasswordFallback),
        );
        return false;
      }
    } catch (e) {
      _showErrorBar(l10n.errorPrefixMsg(e.toString()));
      return false;
    }
  }

  // -------------------------------------------------------------
  // UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBg1, kBg2],
            begin: AlignmentDirectional.topCenter,
            end: AlignmentDirectional.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kTextDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.securitySettingsTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: kTextDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              _sectionTitle(l10n.securitySection),

              _securityCard(
                icon: Icons.lock_rounded,
                title: l10n.changePasswordTitle,
                subtitle: l10n.updateParentPasswordSub,
                color: kGreen1,
                isRtl: isRtl,
                onTap: _showChangeParentPasswordDialog,
              ),

              const SizedBox(height: 14),

              _securityCard(
                icon: Icons.child_care_rounded,
                title: l10n.changeChildPasswordTitle,
                subtitle: children.isEmpty
                    ? l10n.addChildFirstToManage
                    : l10n.resetChildPasswordSub,
                color: kGreen2,
                isRtl: isRtl,
                onTap: children.isEmpty ? null : _showChangeChildPasswordDialog,
              ),

              const SizedBox(height: 16),

              if (isLoadingChildren)
                const Center(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(top: 10),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // UI Helpers
  // -------------------------------------------------------------
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: kTextDark,
        ),
      ),
    );
  }

  Widget _securityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isRtl,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsetsDirectional.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Icon(
          isRtl ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded,
          size: 16,
          color: onTap == null ? Colors.black26 : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  static Widget _fieldLabel(String text) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  static InputDecoration _hassalaFieldDeco({
    required String hint,
    required IconData prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: Icon(prefix, color: kGreen2),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black12.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kGreen2, width: 1.2),
      ),
    );
  }

  void _showErrorBar(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessBar(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2EA49E), // Hassala green
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validatePassword(String pass) {
    return RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*]).{8,}$',
    ).hasMatch(pass);
  }

  void _showPasswordRequirements(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.passwordRequirementsTitle),
        content: Text(l10n.passwordRequirementsList),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}